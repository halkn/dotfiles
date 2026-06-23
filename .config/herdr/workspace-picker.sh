#!/bin/zsh
set -euo pipefail

selected=$(
  herdr workspace list \
    | jq -r '.result.workspaces[] | "[\(.number)] \(.label)\t\(.workspace_id)"' \
    | fzf --style=full --border-label=" Workspaces " --prompt="  " --ansi
) || exit 0

workspace_id=$(echo "$selected" | awk '{print $NF}')
herdr workspace focus "$workspace_id"
