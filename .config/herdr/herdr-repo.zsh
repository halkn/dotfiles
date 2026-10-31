#!/bin/zsh
# alt+n in herdr: pick one of the clones and open a workspace on it.
#
# `repo` serves the list and `hw repo` does the opening, focusing a workspace
# already open on the clone.
set -uo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

whence _ui_require >/dev/null || {
  print -u2 "herdr-repo: $ui_lib not found"
  print -n 'press any key '
  read -rsk1 || true
  exit 1
}
_ui_require herdr-repo repo hw fzf || _ui_die

# Fetched before the picker opens rather than from inside it, so a failure is
# reported instead of showing an empty list.
rows=$(repo list --full-path) || _ui_die
[[ -n $rows ]] || _ui_die herdr-repo 'no clones under $REPO_ROOT'

# A cancelled picker is not a failure.
dir=$(
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" --border-label ' repo ' \
      --prompt 'repo> ' \
      --preview "source ${_UI_LIB}; _ui_git_preview {}"
) || exit 0
[[ -n $dir ]] || exit 0
hw repo "$dir" || _ui_die
