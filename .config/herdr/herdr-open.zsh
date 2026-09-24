#!/bin/zsh
# alt+n in herdr: pick one of the clones and open a workspace on it.
#
# The picker lives here rather than in a zsh function because neither half of it
# belongs to the shell: `repo` serves the list on stdout and herdr does the
# opening. Only the chrome and the preview are shared, from ui.zsh.
set -uo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

whence _ui_require >/dev/null || {
  print -u2 "herdr-open: $ui_lib not found"
  print -n 'press any key '
  read -rsk1 || true
  exit 1
}

_ui_require repo herdr-open || _ui_die
_ui_require fzf herdr-open || _ui_die

# Fetched before the picker opens rather than from inside it, so a failure is
# reported instead of showing an empty list.
rows=$(repo list --full-path) || _ui_die
[[ -n $rows ]] || _ui_die herdr-open 'no clones under $REPO_ROOT'

# A cancelled picker is not a failure.
dir=$(
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" --border-label ' repo ' \
      --prompt 'repo> ' \
      --preview "source ${_UI_LIB}; _ui_git_preview {}"
) || exit 0
[[ -n $dir ]] || exit 0

# Received into a variable first: herdr's own output would otherwise land in the
# popup, and a failure here is reported with it.
out=$(herdr workspace create --cwd "$dir" --focus 2>&1) ||
  _ui_die herdr-open "could not create the workspace: $out"
