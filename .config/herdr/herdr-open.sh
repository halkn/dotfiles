#!/bin/zsh
# alt+n in herdr: `wk open` in a popup. This file exists because the popup runs
# a command rather than a shell, so the functions have to be sourced first; what
# the picker looks like and does is wk.zsh's.
set -euo pipefail

wk_workflow=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows/wk.zsh
if [[ -r $wk_workflow ]]; then
  source "$wk_workflow"
fi

whence _wk_open_pick >/dev/null || {
  print -u2 "herdr-open: $wk_workflow not found"
  exit 1
}

# A cancelled picker is not a failure, and `set -e` would otherwise make the
# popup close on a non-zero status.
_wk_open_pick || exit 0
