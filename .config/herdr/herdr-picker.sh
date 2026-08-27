#!/bin/zsh
# alt+s in herdr: `wt` in a popup. This file exists because the popup runs a
# command rather than a shell, so the functions have to be sourced first; what
# the picker looks like and does is worktree.zsh's.
set -euo pipefail

zsh_workflows=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows
if [[ -r $zsh_workflows/worktree.zsh ]]; then
  source "$zsh_workflows/worktree.zsh"
fi

whence _wt_pick >/dev/null || {
  print -u2 "herdr-picker: $zsh_workflows/worktree.zsh not found"
  exit 1
}

# A cancelled picker is not a failure, and `set -e` would otherwise make the
# popup close on a non-zero status.
_wt_pick || exit 0
