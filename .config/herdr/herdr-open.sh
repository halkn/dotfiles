#!/bin/zsh
# alt+n in herdr: `ws` in a popup. This file exists because the popup runs a
# command rather than a shell, so the functions have to be sourced first; what
# the picker looks like and does is workspace.zsh's. repo.zsh comes along
# because the listing includes its rows and workflow files do not source each
# other.
set -euo pipefail

zsh_workflows=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows
for f in repo workspace; do
  if [[ -r $zsh_workflows/$f.zsh ]]; then
    source "$zsh_workflows/$f.zsh"
  fi
done

whence _ws_pick >/dev/null || {
  print -u2 "herdr-open: $zsh_workflows/workspace.zsh not found"
  exit 1
}

# A cancelled picker is not a failure, and `set -e` would otherwise make the
# popup close on a non-zero status.
_ws_pick || exit 0
