#!/bin/zsh
# alt+g in herdr: `wt new` for a branch you type, on the repository of the
# focused workspace, then open the worktree it prints.
#
# The focused workspace's checkout rather than the popup's cwd is where `wt new`
# runs, so a pane cd'd elsewhere does not change the repository, and a new
# branch forks from that checkout's HEAD. A workspace off a checkout has no path
# in herdr 0.9.1, and the popup's cwd stands in for it.
set -uo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

whence _ui_require >/dev/null || {
  print -u2 "herdr-new: $ui_lib not found"
  print -n 'press any key '
  read -rsk1 || true
  exit 1
}
_ui_require wt herdr-new || _ui_die
_ui_require jq herdr-new || _ui_die

focused=$(_ui_focused_workspace) || _ui_die herdr-new 'herdr could not list the workspaces'
base=${focused#*$'\t'}
if [[ -n $focused && -n $base ]]; then
  cd "$base" || _ui_die herdr-new "cannot enter $base"
fi

# An empty answer is a cancelled popup, not a failure.
branch=''
read -r "branch?branch: " || exit 0
[[ -n $branch ]] || exit 0
dir=$(wt new "$branch") || _ui_die

# A reused worktree may already have a workspace, which is focused rather than
# opened a second time.
rows=$(_ui_workspaces 2>/dev/null) || rows=
for row in ${(f)rows}; do
  fields=("${(@ps:\t:)row}")
  [[ -n ${fields[3]-} && ${fields[3]:A} == "${dir:A}" ]] || continue
  herdr workspace focus "${fields[2]}" >/dev/null || _ui_die herdr-new "herdr could not focus ${fields[2]}"
  exit 0
done
herdr worktree open --path "$dir" --focus >/dev/null || _ui_die herdr-new "herdr could not open $dir"
