#!/usr/bin/env bash
# Replaces Claude Code's `@` file completion with an fd + grep match.
# stdin: {"query": "..."} / stdout: newline-separated paths, of which the first 15 are used.
# fd comes from mise; where it is missing this falls back to rg.
set -euo pipefail

query="$(jq -r '.query // ""' 2>/dev/null)" || query=""
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

if [ -n "$query" ]; then
  filter=(grep -iF -- "$query")
else
  filter=(cat)
fi
list_files | "${filter[@]}" | head -15 || true
