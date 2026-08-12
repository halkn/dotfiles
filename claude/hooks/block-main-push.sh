#!/usr/bin/env bash
# PreToolUse(Bash): ask before a direct push to main/master.
#
# The `permissions.ask` patterns (`Bash(git push * main*)`) require a space before "main",
# so any push that never spells that token out — a colon refspec (`git push origin HEAD:main`),
# a deletion (`git push origin :main`), `--all` — slips past them. This hook parses the push
# instead and resolves the destination branch first. `--mirror` can delete remote-only refs,
# so it is treated as a force push and denied outright rather than asked.
#
# /bin/bash on macOS is 3.2, where an empty array under `set -u` raises unbound variable, so
# arguments are accumulated in plain variables instead of arrays.
#
# A working directory that changes between segments (`cd X && git push`) is not tracked.
set -euo pipefail

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

deny() {
  echo "$1" >&2
  exit 2
}

is_protected_branch() {
  case "$1" in
    main | master)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

# Asks when the destination half of `<src>:<dst>` (or a bare `<ref>`) is main/master.
check_refspec() {
  local refspec="$1" dst
  case "$refspec" in
    *:*)
      dst="${refspec#*:}"
      ;;
    *)
      dst="$refspec"
      ;;
  esac
  [ -n "$dst" ] || return 0
  dst="${dst#refs/heads/}"
  if is_protected_branch "$dst"; then
    ask "main/master への直接 push（refspec: ${refspec}）を実行してよいですか?"
  fi
}

run_git() {
  if [ -n "$git_dir" ]; then
    git -C "$git_dir" "$@"
  else
    git "$@"
  fi
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
  [ "$base" = "git" ] || continue
  shift

  # Skip git's global options to reach the subcommand, keeping -C as the working directory.
  git_dir=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      -C)
        git_dir="${2:-}"
        shift 2
        ;;
      -c)
        shift 2
        ;;
      push)
        break
        ;;
      -*)
        shift
        ;;
      *)
        break
        ;;
    esac
  done
  [ "${1:-}" = "push" ] || continue
  shift

  mirror=0
  all=0
  saw_remote=0
  saw_refspec=0
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --)
        shift
        while [ "$#" -gt 0 ]; do
          if [ "$saw_remote" -eq 0 ]; then
            saw_remote=1
          else
            saw_refspec=1
            check_refspec "$1"
          fi
          shift
        done
        ;;
      --mirror)
        mirror=1
        shift
        ;;
      --all)
        all=1
        shift
        ;;
      -o | --push-option)
        shift 2
        ;;
      -*)
        shift
        ;;
      *)
        if [ "$saw_remote" -eq 0 ]; then
          saw_remote=1
        else
          saw_refspec=1
          check_refspec "$1"
        fi
        shift
        ;;
    esac
  done

  if [ "$mirror" -eq 1 ]; then
    deny "git push --mirror は main/master を含む全 ref に強制的に影響する（リモートにしか無い ref の削除もありうる）ため禁止です。個別ブランチを指定して push してください。"
  fi

  if [ "$all" -eq 1 ]; then
    if run_git rev-parse --verify --quiet refs/heads/main >/dev/null 2>&1 ||
      run_git rev-parse --verify --quiet refs/heads/master >/dev/null 2>&1; then
      ask "git push --all はローカルの main/master ブランチも含めて push します。実行してよいですか?"
    fi
    continue
  fi

  # Without an explicit refspec (`git push` / `git push origin`) the current branch is
  # the destination.
  if [ "$saw_refspec" -eq 0 ]; then
    branch="$(run_git branch --show-current 2>/dev/null || true)"
    if [ -n "$branch" ] && is_protected_branch "$branch"; then
      ask "現在のブランチ ($branch) は main/master です。main/master への直接 push を実行してよいですか?"
    fi
  fi
done <<EOF
$segments
EOF

exit 0
