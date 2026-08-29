#!/bin/zsh
# alt+g in herdr: `wk new` in a popup, replacing herdr's own new_worktree so
# that every worktree is placed and branched the same way. The popup runs a
# command rather than a shell, so the functions have to be sourced first.
set -euo pipefail

wk_workflow=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows/wk.zsh
if [[ -r $wk_workflow ]]; then
  source "$wk_workflow"
fi

whence _wk_new >/dev/null || {
  print -u2 "herdr-new: $wk_workflow not found"
  exit 1
}

# The popup opens on the cwd of the pane it was called from, which is the
# repository the branch is taken from.
_wk_in_repo || exit 1

# An empty answer is a cancelled popup, not a failure.
branch=''
read -r "branch?branch: " || exit 0
[[ -n $branch ]] || exit 0

_wk_new "$branch"
