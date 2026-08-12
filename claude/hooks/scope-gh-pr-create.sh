#!/usr/bin/env bash
# PreToolUse(Bash): ask when `gh pr create` targets a repository outside github.com/halkn.
#
# settings.json is global (symlinked to ~/.claude/settings.json), so PR creation can fire in
# work repositories that autoMode.environment never meant to trust, where the classifier's
# judgement is the only gate. Owner is a deterministic criterion to gate on instead.
#
# A working directory that changes between segments (`cd X && gh pr create`) is not tracked,
# and neither a remote named other than origin nor gh's own repo resolution (upstream
# tracking) is reproduced here. An owner that cannot be resolved falls through to ask.
set -euo pipefail

TRUSTED_OWNER="halkn"

command="$(jq -r '.tool_input.command // ""')"

ask() {
  jq -n --arg reason "$1" '{
		hookSpecificOutput: {
			hookEventName: "PreToolUse",
			permissionDecision: "ask",
			permissionDecisionReason: $reason
		}
	}'
  exit 0
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

# Command substitutions and subshells open a new command too, so their opening symbols are
# turned into newlines before the ordinary separators are folded into segments.
segments="$(printf '%s' "$command" | sed -E 's/\$\(/\n/g; s/`/\n/g' | tr '|;&()' '\n\n\n\n\n')"

set -f # `set -- $seg` below would otherwise glob-expand the segment
while IFS= read -r seg; do
  # shellcheck disable=SC2086
  set -- $seg

  # Skip leading assignments and wrapper commands to reach the real program.
  while [ "$#" -gt 0 ]; do
    case "$1" in
      *=*)
        shift
        ;;
      sudo | doas | env | nohup | time | exec | command | builtin | watch | xargs | stdbuf | nice | ionice | setsid)
        shift
        ;;
      *)
        break
        ;;
    esac
  done

  prog="${1:-}"
  base="${prog##*/}"
  [ "$base" = "gh" ] || continue
  shift

  [ "${1:-}" = "pr" ] || continue
  shift
  [ "${1:-}" = "create" ] || continue
  shift

  repo_flag=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --repo=*)
        repo_flag="${1#--repo=}"
        ;;
      --repo | -R)
        repo_flag="${2:-}"
        ;;
    esac
    shift
  done

  if [ -n "$repo_flag" ]; then
    owner="$(extract_owner "$repo_flag")"
  else
    origin_url="$(git config --get remote.origin.url 2>/dev/null || true)"
    owner="$(extract_owner "$origin_url")"
  fi

  if [ -z "$owner" ]; then
    ask "gh pr create の対象リポジトリの owner を特定できませんでした。実行してよいですか?"
  fi

  lower_owner="$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')"
  if [ "$lower_owner" != "$TRUSTED_OWNER" ]; then
    ask "gh pr create の対象リポジトリ owner が \"${owner}\" です（信頼範囲は github.com/${TRUSTED_OWNER} 配下）。実行してよいですか?"
  fi
done <<EOF
$segments
EOF

exit 0
