#!/bin/zsh
# alt+r in herdr. The pane is labelled because the label is the only thing the
# next press has to go on.
set -euo pipefail

workspace=${HERDR_ACTIVE_WORKSPACE_ID:-}
tab=${HERDR_ACTIVE_TAB_ID:-}
active=${HERDR_ACTIVE_PANE_ID:-}
[[ -n $workspace && -n $tab && -n $active ]] || exit 1

# `pane list` filters by workspace only, so the tab is matched here.
open=$(herdr pane list --workspace "$workspace" \
  | jq -r --arg tab "$tab" \
  'first(.result.panes[] | select(.label == "hunk" and .tab_id == $tab) | .pane_id) // empty')

if [[ -n $open ]]; then
  herdr pane close "$open"
  exit 0
fi

pane=$(herdr pane split --pane "$active" --direction right --ratio 0.5 \
  --cwd "${HERDR_ACTIVE_PANE_CWD:-$PWD}" --focus | jq -r '.result.pane.pane_id')
# A detached keybinding has nowhere to report a failed split.
[[ -n $pane && $pane != null ]] || exit 1
herdr pane rename "$pane" hunk
herdr pane run "$pane" "hunk diff --watch"
