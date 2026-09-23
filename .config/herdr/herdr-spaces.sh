#!/bin/zsh
# alt+s in herdr: the open workspaces, one picker to focus one (Enter) or take
# away the selected ones (Tab to select, ctrl-x).
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
# Read once per batch.
typeset -a worktrees
load_worktrees() {
  local line
  worktrees=()
  for line in ${(f)"$(wt list --full-path)"}; do
    worktrees+=("${line:A}")
  done
}

is_worktree() {
  local dir=${1:A} wt_dir
  for wt_dir in "${worktrees[@]}"; do
    [[ $wt_dir == "$dir" ]] && return 0
  done
  return 1
}

# `wt rm` removes nothing while a decision is missing and says which by its
# status: 2 asks for -f (discard local changes), 3 for -D or -k (an unmerged
# branch). Each is asked on its own, with wt's reason on screen, and the answers
# accumulate until wt goes through or refuses for good (1).
remove_worktree() {
  local dir=$1 shown=$2
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
        _ui_confirm "discard the local changes in $shown?" || return 1
        flags+=(-f)
        ;;
      3)
        if _ui_confirm "delete the unmerged branch of $shown too? (no keeps it)"; then
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

# The worktree goes first, so a workspace whose `wt rm` is refused stays open.
take_away() {
  local ws=$1 dir=$2 shown=$3
  if [[ -n $dir ]] && is_worktree "$dir"; then
    remove_worktree "$dir" "$shown" || return 1
  fi
  herdr workspace close "$ws" >/dev/null || {
    print -u2 "herdr-spaces: herdr could not close $ws"
    return 1
  }
}

# One confirmation for the whole selection, then wt's own questions per
# worktree. The focused workspace is left out as `wt rm` refuses the worktree it
# stands in: closing it would end the shells the popup was opened from.
take_away_all() {
  local focused line shown
  local -a fields targets
  local -i rc=0
  focused=$(_ui_focused_workspace) || focused=
  focused=${focused%%$'\t'*}
  load_worktrees
  for line in "$@"; do
    fields=("${(@ps:\t:)line}")
    shown=${(j: :)${=fields[1]}}
    if [[ ${fields[2]} == "$focused" ]]; then
      print -u2 "herdr-spaces: $shown is the workspace you are in; left open"
      continue
    fi
    if [[ -n ${fields[3]-} ]] && is_worktree "${fields[3]}"; then
      print -r -- "remove the worktree  $shown"
    else
      print -r -- "close                $shown"
    fi
    targets+=("$line")
  done
  ((${#targets} > 0)) || {
    _ui_pause
    return 0
  }
  _ui_confirm 'go ahead?' || return 0
  for line in "${targets[@]}"; do
    fields=("${(@ps:\t:)line}")
    take_away "${fields[2]}" "${fields[3]-}" "${(j: :)${=fields[1]}}" || rc=1
  done
  ((rc == 0)) || _ui_pause
}

# Back to the picker after taking some away. Enter drops the selection so that
# it always goes to the row under the cursor. A cancelled picker is not a
# failure, and `set -e` would otherwise close the popup on a non-zero status.
while true; do
  rows=$(_ui_workspaces) || _ui_die herdr-spaces 'herdr could not list the workspaces'
  [[ -n $rows ]] || exit 0
  picked=$(
    print -r -- "$rows" \
      | fzf "${_UI_FZF_CHROME[@]}" --border-label ' workspaces ' \
        --multi --delimiter '\t' --with-nth 1 --expect ctrl-x \
        --bind 'enter:clear-multi+accept' \
        --prompt 'go> ' \
        --header 'Enter: go / Tab: select / ctrl-x: remove the worktrees or close' \
        --preview "source ${_UI_LIB}; _ui_git_preview {3}"
  ) || exit 0
  lines=("${(@f)picked}")
  key=${lines[1]-}
  lines=("${(@)lines[2,-1]}")
  ((${#lines} > 0)) || exit 0

  if [[ $key != ctrl-x ]]; then
    fields=("${(@ps:\t:)lines[1]}")
    herdr workspace focus "${fields[2]}" >/dev/null ||
      _ui_die herdr-spaces "herdr could not focus ${fields[2]}"
    exit 0
  fi
  take_away_all "${lines[@]}"
done
