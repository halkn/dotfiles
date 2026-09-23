#!/bin/zsh
# alt+s in herdr: the open workspaces, one picker to focus one (Enter) or take
# one away (ctrl-x).
#
# Taking away a workspace on a worktree under $WT_ROOT removes the worktree with
# `wt rm` and then closes the workspace; any other workspace is only closed, so
# a clone is never deleted from here. A worktree without a workspace is reopened
# with alt+g (herdr-new.sh) or removed with `wt rm` from a shell.
set -euo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

whence _ui_require >/dev/null || {
  print -u2 "herdr-spaces: $ui_lib not found"
  print -n 'press any key '
  read -rsk1 || true
  exit 1
}
_ui_require fzf herdr-spaces || _ui_die
_ui_require jq herdr-spaces || _ui_die
_ui_require wt herdr-spaces || _ui_die

# Whether a worktree is one is `wt list`'s to say, the same test `wt rm` applies.
is_worktree() {
  local dir=${1:A} line
  for line in ${(f)"$(wt list --full-path)"}; do
    [[ ${line:A} == "$dir" ]] && return 0
  done
  return 1
}

# `wt rm` removes nothing while a decision is missing and says which by its
# status: 2 asks for -f (discard local changes), 3 for -D or -k (an unmerged
# branch). Each is asked on its own, with wt's reason on screen, and the answers
# accumulate until wt goes through or refuses for good (1).
remove_worktree() {
  local dir=$1
  local -a flags
  local -i st
  while true; do
    st=0
    wt rm "${flags[@]}" "$dir" >/dev/null || st=$?
    case $st in
      0)
        return 0
        ;;
      2)
        _ui_confirm 'discard its local changes?' || return 1
        flags+=(-f)
        ;;
      3)
        if _ui_confirm 'delete its unmerged branch too? (no keeps the branch)'; then
          flags+=(-D)
        else
          flags+=(-k)
        fi
        ;;
      *)
        return 1
        ;;
    esac
  done
}

# The focused workspace is refused as `wt rm` refuses the worktree it stands in:
# closing it would end the shells the popup was opened from.
take_away() {
  local ws=$1 dir=$2 shown=$3 focused
  focused=$(_ui_focused_workspace) || focused=
  if [[ $ws == "${focused%%$'\t'*}" ]]; then
    print -u2 "herdr-spaces: $shown is the workspace you are in"
    return 1
  fi
  if [[ -n $dir ]] && is_worktree "$dir"; then
    _ui_confirm "remove the worktree $shown?" || return 0
    remove_worktree "$dir" || return 1
  else
    _ui_confirm "close $shown?" || return 0
  fi
  herdr workspace close "$ws" >/dev/null || {
    print -u2 "herdr-spaces: herdr could not close $ws"
    return 1
  }
}

# Back to the picker after taking one away, so several go in one popup. A
# cancelled picker is not a failure, and `set -e` would otherwise close the
# popup on a non-zero status.
while true; do
  rows=$(_ui_workspaces) || _ui_die herdr-spaces 'herdr could not list the workspaces'
  [[ -n $rows ]] || exit 0
  picked=$(
    print -r -- "$rows" \
      | fzf "${_UI_FZF_CHROME[@]}" --border-label ' workspaces ' \
        --delimiter '\t' --with-nth 1 --expect ctrl-x \
        --prompt 'go> ' \
        --header 'Enter: go / ctrl-x: remove the worktree or close' \
        --preview "source ${_UI_LIB}; _ui_git_preview {3}"
  ) || exit 0
  key=${picked%%$'\n'*}
  line=${picked#*$'\n'}
  [[ -n $line && $line != "$picked" ]] || exit 0
  fields=("${(@ps:\t:)line}")
  ws=${fields[2]}
  dir=${fields[3]-}

  if [[ $key != ctrl-x ]]; then
    herdr workspace focus "$ws" >/dev/null || _ui_die herdr-spaces "herdr could not focus $ws"
    exit 0
  fi
  take_away "$ws" "$dir" "${(j: :)${=fields[1]}}" || _ui_pause
done
