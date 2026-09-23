#!/bin/zsh
# alt+n in herdr: pick one of the clones and open a workspace on it.
#
# The picker lives here rather than in a zsh function because neither half of it
# belongs to the shell: `repo` serves the list on stdout and herdr does the
# opening. Only the chrome and the preview are shared, from ui.zsh.
set -euo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

whence _ui_require >/dev/null || {
  print -u2 "herdr-open: $ui_lib not found"
  exit 1
}

_ui_require repo herdr-open || exit 1
_ui_require fzf herdr-open || exit 1

# Fetched before the picker opens rather than from inside it, so a failure is
# reported instead of showing an empty list.
rows=$(repo list --full-path) || exit 1
[[ -n $rows ]] || {
  print -u2 'herdr-open: no clones under $REPO_ROOT'
  exit 1
}

# A cancelled picker is not a failure, and `set -e` would otherwise close the
# popup on a non-zero status.
dir=$(
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" --border-label ' repo ' \
      --prompt 'repo> ' \
      --preview "source ${_UI_LIB}; _ui_git_preview {}"
) || exit 0
[[ -n $dir ]] || exit 0

# Received into a variable first: herdr's own output would otherwise land in the
# popup, and a failure here has to be reported rather than swallowed by `set -e`.
out=$(herdr workspace create --cwd "$dir" --focus 2>&1) || {
  print -u2 "herdr-open: could not create the workspace: $out"
  exit 1
}
