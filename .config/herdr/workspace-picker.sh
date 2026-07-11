#!/bin/zsh
set -euo pipefail

if command -v jaq >/dev/null 2>&1; then
  JQ_BIN=jaq
else
  JQ_BIN=jq
fi

selected=$(
  herdr workspace list \
    | "$JQ_BIN" -r '.result.workspaces[] | "[\(.number)] \(.label)\t\(.workspace_id)"' \
    | fzf --style=full --border-label=" Workspaces " --prompt="  " --ansi
) || exit 0

workspace_id=$(printf '%s' "$selected" | awk -F'\t' '{print $2}')
[[ -n $workspace_id ]] || exit 0
herdr workspace focus "$workspace_id"
