#!/usr/bin/env bash
# PreToolUse(Bash): guard the gh calls that reach past the working branch.
#
# - deny: showing the token, widening or changing the login (`gh auth token|refresh|login|
#   logout|switch|setup-git`, `gh auth status --show-token`), and deleting a repository
#   (`gh repo delete`, DELETE on the repository through `gh api`)
# - ask: merging, moving the main/master ref, and changing branch protection, rulesets or the
#   repository itself, through gh's own subcommands or `gh api`; aliases, which would hide any
#   of these from this hook
# - ask: `gh pr create` for a repository outside github.com/halkn
#
# `permissions` lists the plain forms. gh also takes flags before the subcommand
# (`gh pr -R x merge`), which no prefix pattern reaches, and `gh api` reads and writes through
# the same prefix, so the subcommand, method and endpoint are resolved here.
#
# The ruleset requires a pull request but no approval, so whoever holds the token can merge;
# why merges are asked every time is in docs/claude-code.md. settings.json is global, so PR
# creation also fires in work repositories, where the owner is a deterministic criterion.
#
# gh sends GET unless a field (-f/-F) or --input is given, which switches it to POST; --method
# overrides both. A body read from a file cannot be inspected and is asked. Placeholders and
# origin are resolved in the input `cwd`, as gh does. Neither a remote named other than origin
# nor gh's own repo resolution (upstream tracking) is reproduced, and an owner that cannot be
# resolved falls through to ask.
set -euo pipefail

TRUSTED_OWNER="halkn"

lib="${BASH_SOURCE[0]%/*}/lib/commands.jq"
[ -r "$lib" ] || {
  echo "hook library missing: $lib" >&2
  exit 2
}

input="$(cat)"
command="$(printf '%s' "$input" | jq -r '.tool_input.command // ""')"
cwd="$(printf '%s' "$input" | jq -r '.cwd // "."')"
commands="$(printf '%s' "$input" | jq -r -f "$lib")"

ask_reason=""

ask() {
  [ -n "$ask_reason" ] || ask_reason="$1"
}

deny() {
  echo "$1" >&2
  exit 2
}

# Mutations that merge, move a ref, or change protection, rulesets or repository settings.
mutations='(^|[^[:alnum:]_])(mergePullRequest|mergeBranch|enablePullRequestAutoMerge|enqueuePullRequest|updateRef|updateRefs|deleteRef|createCommitOnBranch|(create|update|delete)BranchProtectionRule|(create|update|delete)RepositoryRuleset|updateRepository|(un)?archiveRepository)([^[:alnum:]_]|$)'

repo='^repos/[^/]+/[^/]+'
protected_ref='refs/heads/(main|master)([^[:alnum:]_./-]|$)'

current_branch() {
  git -C "$cwd" branch --show-current 2>/dev/null || true
}

# Accepts "git@github.com:OWNER/REPO.git", "https://github.com/OWNER/REPO" and the short
# "OWNER/REPO" form that --repo allows.
extract_owner() {
  local url="$1" rest owner
  case "$url" in
    *github.com[:/]*)
      rest="${url#*github.com[:/]}"
      owner="${rest%%/*}"
      ;;
    */*)
      owner="${url%%/*}"
      ;;
    *)
      owner=""
      ;;
  esac
  printf '%s' "$owner"
}

check_pr_create() {
  local repo_flag="" owner lower_owner
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --repo=*)
        repo_flag="${1#--repo=}"
        ;;
      --repo | -R)
        repo_flag="${2:-}"
        ;;
      -R?*)
        repo_flag="${1#-R}"
        ;;
    esac
    shift
  done

  if [[ "$command" =~ (^|[^[:alnum:]_])GH_REPO= ]]; then
    ask "gh pr create の対象リポジトリが GH_REPO で指定されています。実行してよいですか?"
    return 0
  fi
  if [ -n "$repo_flag" ]; then
    owner="$(extract_owner "$repo_flag")"
  else
    owner="$(extract_owner "$(git -C "$cwd" config --get remote.origin.url 2>/dev/null || true)")"
  fi
  if [ -z "$owner" ]; then
    ask "gh pr create の対象リポジトリの owner を特定できませんでした。実行してよいですか?"
    return 0
  fi
  lower_owner="$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')"
  if [ "$lower_owner" != "$TRUSTED_OWNER" ]; then
    ask "gh pr create の対象リポジトリ owner が \"${owner}\" です（信頼範囲は github.com/${TRUSTED_OWNER} 配下）。実行してよいですか?"
  fi
}

check_auth_status() {
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --show-token*)
        deny "gh auth status --show-token はトークンを表示するため禁止です。"
        ;;
      -h | --hostname)
        shift
        ;;
      -a*t* | -t*)
        deny "gh auth status -t はトークンを表示するため禁止です。"
        ;;
    esac
    shift || true
  done
}

# Takes the words after `gh api`.
check_api() {
  local endpoint="" method="" has_body=0 from_file=0 protected_body=0 field
  while [ "$#" -gt 0 ]; do
    field=""
    case "$1" in
      -X | --method)
        method="${2:-}"
        shift
        ;;
      --method=*)
        method="${1#--method=}"
        ;;
      -X?*)
        method="${1#-X}"
        ;;
      -f | -F | --field | --raw-field)
        field="${2:-}"
        shift
        ;;
      --field=* | --raw-field=*)
        field="${1#*=}"
        ;;
      -f?* | -F?*)
        field="${1#-?}"
        ;;
      --input)
        has_body=1
        from_file=1
        shift
        ;;
      --input=*)
        has_body=1
        from_file=1
        ;;
      -H | --header | -q | --jq | -t | --template | --hostname | --cache | -p | --preview)
        shift
        ;;
      -*) ;;
      *)
        [ -n "$endpoint" ] || endpoint="$1"
        ;;
    esac
    if [ -n "$field" ]; then
      has_body=1
      case "$field" in
        *=@*)
          from_file=1
          ;;
      esac
      if [[ "$field" =~ $protected_ref ]]; then
        protected_body=1
      fi
    fi
    shift || true
  done
  [ -n "$endpoint" ] || return 0

  endpoint="${endpoint#http*://*/}"
  endpoint="${endpoint#api/v3/}"
  endpoint="${endpoint#/}"
  endpoint="${endpoint%%\#*}"
  endpoint="${endpoint%%\?*}"
  endpoint="${endpoint%/}"
  if [[ "$endpoint" =~ ^repositories/([0-9]+)(/.*)?$ ]]; then
    endpoint="repos/id/${BASH_REMATCH[1]}${BASH_REMATCH[2]}"
  fi

  if [ -z "$method" ]; then
    if [ "$has_body" -eq 1 ]; then
      method=POST
    else
      method=GET
    fi
  fi
  method="$(printf '%s' "$method" | tr '[:lower:]' '[:upper:]')"
  local action="gh api ${method} ${endpoint}"

  if [ "$endpoint" = "graphql" ]; then
    if [ "$from_file" -eq 1 ]; then
      ask "GraphQL のクエリや変数をファイルから読む gh api は内容を確かめられません。実行してよいですか?"
    elif [[ "$command" =~ $mutations ]]; then
      ask "GraphQL の ${BASH_REMATCH[2]}（merge・ref・保護・リポジトリ設定の変更）を実行してよいですか?"
    fi
    return 0
  fi

  case "$method" in
    GET | HEAD)
      return 0
      ;;
  esac

  if [ "$method" = "DELETE" ] && [[ "$endpoint" =~ $repo$ ]]; then
    deny "リポジトリの削除（${action}）は禁止です。必要ならユーザーが Claude Code の外で行ってください。"
  fi

  if [[ "$endpoint" =~ $repo/git/refs/heads/(\{branch\}|:branch)$ ]]; then
    case "$(current_branch)" in
      main | master)
        ask "${action}（{branch} は現在の main/master）を実行してよいですか?"
        ;;
    esac
    return 0
  fi

  if [[ "$endpoint" =~ $repo/pulls/[^/]+/merge$ ]] ||
    [[ "$endpoint" =~ $repo/(merges|merge-upstream|transfer)$ ]] ||
    [[ "$endpoint" =~ $repo/git/refs/heads/(main|master)$ ]] ||
    [[ "$endpoint" =~ $repo/branches/[^/]+/(protection(/.*)?|rename)$ ]] ||
    [[ "$endpoint" =~ $repo/rulesets(/.*)?$ ]] ||
    [[ "$endpoint" =~ ^orgs/[^/]+/rulesets(/.*)?$ ]] ||
    [[ "$endpoint" =~ $repo/contents/ ]] ||
    [[ "$endpoint" =~ $repo$ ]]; then
    ask "${action}（main/master かその保護・リポジトリ設定を変える操作）を実行してよいですか?"
    return 0
  fi

  if [[ "$endpoint" =~ $repo/git/refs$ ]]; then
    if [ "$protected_body" -eq 1 ]; then
      ask "${action}（main/master の ref の作成）を実行してよいですか?"
    elif [ "$from_file" -eq 1 ]; then
      ask "${action}（ref をファイルから読むので対象を確かめられません）を実行してよいですか?"
    fi
  fi
}

set -f # `set -- $line` below would otherwise glob-expand the words
while IFS= read -r line; do
  IFS=$'\037'
  # shellcheck disable=SC2086
  set -- $line
  IFS=$' \t\n'

  [ "${1:-}" = "gh" ] || continue
  shift

  # gh resolves the subcommand past any flags in front of it; -R / --hostname take a value.
  group=""
  sub=""
  skip=0
  for word in "$@"; do
    if [ "$skip" -eq 1 ]; then
      skip=0
      continue
    fi
    case "$word" in
      -R | --repo | --hostname | -h)
        skip=1
        ;;
      -*) ;;
      *)
        if [ -z "$group" ]; then
          group="$word"
          [ "$group" != "api" ] || break
        else
          sub="$word"
          break
        fi
        ;;
    esac
  done

  case "$group $sub" in
    "api "*)
      while [ "${1:-}" != "api" ]; do shift; done
      shift
      check_api "$@"
      ;;
    "pr merge")
      ask "gh pr merge（main/master への merge）を実行してよいですか?"
      ;;
    "pr create" | "pr new")
      check_pr_create "$@"
      ;;
    "repo delete")
      deny "gh repo delete は禁止です。必要ならユーザーが Claude Code の外で行ってください。"
      ;;
    "repo edit" | "repo archive" | "repo unarchive" | "repo rename" | "repo sync")
      ask "gh repo ${sub}（リポジトリ設定・default branch・ブランチの内容を変える操作）を実行してよいですか?"
      ;;
    "auth token" | "auth refresh" | "auth login" | "auth logout" | "auth switch" | "auth setup-git")
      deny "gh auth ${sub} は禁止です（トークンの表示・権限や認証状態の変更）。認証は Claude Code の外のターミナルで行ってください。"
      ;;
    "auth status")
      check_auth_status "$@"
      ;;
    "alias set" | "alias import")
      ask "gh alias ${sub}（以降のコマンドがガードの照合に当たらなくなる）を実行してよいですか?"
      ;;
  esac
done <<EOF
$commands
EOF

if [ -n "$ask_reason" ]; then
  jq -n --arg reason "$ask_reason" '{
		hookSpecificOutput: {
			hookEventName: "PreToolUse",
			permissionDecision: "ask",
			permissionDecisionReason: $reason
		}
	}'
fi

exit 0
