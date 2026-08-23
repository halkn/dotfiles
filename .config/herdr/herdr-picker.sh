#!/bin/zsh
# alt+s in herdr. Everything the picker does - listing the places and the
# agents, previewing, going there, removing a worktree - is `nav` (see
# .config/zsh/workflows/nav.zsh), the same code `wt` and `repo` run. Only the
# chrome differs, because this one opens in a herdr popup rather than in a
# terminal that already has a shell in it.
set -euo pipefail

zsh_workflows=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows
for lib in repo.zsh worktree.zsh nav.zsh; do
  if [[ -r $zsh_workflows/$lib ]]; then
    source "$zsh_workflows/$lib"
  fi
done

whence _nav_go >/dev/null || {
  print -u2 "herdr-picker: $zsh_workflows/nav.zsh not found"
  exit 1
}

# FZF_DEFAULT_OPTS is exported and sizes the picker for a terminal window, so
# the popup restates what it needs: it is its own window already, and it is
# narrow enough that a preview beside the list would not fit.
#
# A cancelled picker is not a failure, and `set -e` would otherwise make the
# popup close on a non-zero status.
_nav_go herdr-picker '' \
  --height=100% \
  --style=full \
  --border-label=' herdr ' \
  --preview-window 'down:60%:wrap' || exit 0
