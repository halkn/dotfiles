#!/bin/zsh
# alt+s in herdr: clean up the open workspaces. Tab selects several, Enter
# takes them away after one confirmation: a worktree under $WT_ROOT is removed
# with `hw rm`, any other workspace is only closed with `hw close`. Going to a
# workspace is herdr's own Goto (prefix+g) and sidebar.
set -uo pipefail

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
_ui_require hw herdr-spaces || _ui_die
_ui_require fzf herdr-spaces || _ui_die

# Standing in the focused checkout is what makes `hw rm` refuse it.
dir=$(hw focused) || _ui_die
cd "$dir" || _ui_die herdr-spaces "cannot enter $dir"
rows=$(hw spaces) || _ui_die
[[ -n $rows ]] || _ui_die herdr-spaces 'no other workspaces'

picked=$(
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" --border-label ' workspaces ' \
      --multi --delimiter '\t' --with-nth 1 --prompt 'clean up> ' \
      --header 'Tab: select / Enter: remove the worktrees, close the rest' \
      --preview "source ${_UI_LIB}; _ui_git_preview {4}"
) || exit 0
lines=("${(@f)picked}")
for line in "${lines[@]}"; do
  f=("${(@ps:\t:)line}")
  print -r -- "${f[2]}  ${f[1]}"
done
_ui_confirm 'go ahead?' || exit 0

# A refused rm is shown and offered once more with -f; nothing else is asked.
rc=0
for line in "${lines[@]}"; do
  f=("${(@ps:\t:)line}")
  hw "${f[2]}" "${f[3]}" && continue
  [[ ${f[2]} == rm ]] &&
    _ui_confirm "remove ${f[1]} anyway, discarding its changes and what runs in it?" &&
    hw rm -f "${f[3]}" && continue
  rc=1
done
((rc == 0)) || _ui_pause
