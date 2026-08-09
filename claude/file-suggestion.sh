#!/usr/bin/env bash
# Replaces Claude Code's `@` file completion with an fd + fzf fuzzy match.
# stdin: {"query": "..."} / stdout: newline-separated paths, of which the first 15 are used.
# fd and fzf come from mise; where they are missing this falls back to rg and grep.
set -euo pipefail

if command -v jaq >/dev/null 2>&1; then
  JQ_BIN=jaq
else
  JQ_BIN=jq
fi

query="$("$JQ_BIN" -r '.query // ""' 2>/dev/null)" || query=""
cd "${CLAUDE_PROJECT_DIR:-.}"

run_with_timeout() {
  if command -v timeout >/dev/null 2>&1; then
    timeout 2 "$@"
  elif command -v gtimeout >/dev/null 2>&1; then
    gtimeout 2 "$@"
  else
    "$@"
  fi
}

list_files() {
  if command -v fd >/dev/null 2>&1; then
    run_with_timeout fd --type f --hidden --exclude .git
  else
    run_with_timeout rg --files --hidden
  fi
}

if [ -n "$query" ] && command -v fzf >/dev/null 2>&1; then
  filter=(fzf --filter "$query")
elif [ -n "$query" ]; then
  filter=(grep -iF -- "$query")
else
  filter=(cat)
fi
list_files | "${filter[@]}" | head -15 || true
