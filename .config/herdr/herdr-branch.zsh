#!/bin/zsh
# alt+g in herdr: pick a branch of the focused workspace's repository, or type a
# new one, and open its worktree with `hw branch`.
#
# The focused workspace's checkout rather than the popup's cwd is the
# repository, so a pane cd'd elsewhere does not change it, and a new branch
# forks from that checkout's HEAD.
set -uo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

whence _ui_require >/dev/null || {
  print -u2 "herdr-branch: $ui_lib not found"
  print -n 'press any key '
  read -rsk1 || true
  exit 1
}
_ui_require hw herdr-branch || _ui_die
_ui_require fzf herdr-branch || _ui_die

dir=$(hw focused) || _ui_die
cd "$dir" || _ui_die herdr-branch "cannot enter $dir"
rows=$(hw branches) || _ui_die

# fzf exits 1 when the typed name matches no row, which is how a new branch is
# asked for; only 130 is a cancelled picker. Splitting on \n keeps the empty
# query line, which (f) would drop.
picked=$(
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" --border-label ' branch ' \
      --delimiter '\t' --with-nth 1 --print-query --expect alt-enter \
      --prompt 'branch> ' \
      --header 'Enter: open / no match: create the typed name / alt-enter: create it anyway' \
      --preview "source ${_UI_LIB}; _ui_branch_preview {2}"
)
case $? in
  0 | 1) ;;
  130)
    exit 0
    ;;
  *)
    _ui_die herdr-branch 'fzf failed'
    ;;
esac
lines=("${(@ps:\n:)picked}")
query=${lines[1]-} key=${lines[2]-} row=${lines[3]-}
name=${row#*$'\t'}
[[ $key != alt-enter && -n $row ]] || name=$query
[[ -n $name ]] || exit 0
hw branch "$name" || _ui_die
