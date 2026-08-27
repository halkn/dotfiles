#!/bin/zsh
# alt+s in herdr. The listing, the preview and the jump are `wt` (see
# .config/zsh/workflows/worktree.zsh); only the chrome differs, because this one
# opens in a popup rather than in a terminal that already has a shell in it.
set -euo pipefail

zsh_workflows=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows
if [[ -r $zsh_workflows/worktree.zsh ]]; then
  source "$zsh_workflows/worktree.zsh"
fi

whence _wt_pick >/dev/null || {
  print -u2 "herdr-picker: $zsh_workflows/worktree.zsh not found"
  exit 1
}

# FZF_DEFAULT_OPTS is exported and sizes the picker for a terminal window, so
# the popup restates what it needs: it is its own window already, and it is
# narrow enough that a preview beside the list would not fit.
#
# A cancelled picker is not a failure, and `set -e` would otherwise make the
# popup close on a non-zero status.
_wt_pick herdr-picker \
  --height=100% \
  --style=full \
  --border-label=' herdr ' \
  --preview-window 'down:60%:wrap' || exit 0
