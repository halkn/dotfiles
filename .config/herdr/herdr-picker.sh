#!/bin/zsh
# alt+s in herdr: pick one of the open workspaces and focus it.
#
# Only what herdr has open is offered. A worktree becomes a workspace when it is
# created (herdr-wt.sh), so one without a workspace is reopened from there.
set -euo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

# A popup closes as soon as its command ends, taking what was printed with it.
die() {
  [[ -z ${1:-} ]] || print -u2 "herdr-picker: $1"
  print -n 'press any key '
  read -rsk1 || true
  exit 1
}

whence _ui_require >/dev/null || die "$ui_lib not found"
_ui_require fzf herdr-picker || die
_ui_require jq herdr-picker || die

workspaces=$(herdr workspace list) || die 'herdr could not list the workspaces'
rows=$(print -r -- "$workspaces" | jq -r '
  .result.workspaces[]?
  | [.workspace_id, (.number | tostring), .label, (.worktree.checkout_path // "")]
  | @tsv
') || die 'could not read the workspace list'
[[ -n $rows ]] || exit 0

wt_root=$(wt root 2>/dev/null) || wt_root=
repo_root=$(repo root 2>/dev/null) || repo_root=

# A path under either root reads as what it is - <owner>/<repo>/<branch> or
# <host>/<owner>/<repo> - and anything else keeps its full path.
lines=()
for row in ${(f)rows}; do
  fields=("${(@ps:\t:)row}")
  dir=${fields[4]-}
  shown=${dir/#$HOME/'~'}
  [[ -n $wt_root && $dir == "$wt_root"/* ]] && shown=${dir#"$wt_root"/}
  [[ -n $repo_root && $dir == "$repo_root"/* ]] && shown=${dir#"$repo_root"/}
  lines+=("$(printf '[%s] %-24s %s\t%s\t%s' "${fields[2]}" "${fields[3]-}" "$shown" "${fields[1]}" "$dir")")
done

# A cancelled picker is not a failure, and `set -e` would otherwise close the
# popup on a non-zero status.
ws=$(
  print -rl -- "${lines[@]}" \
    | fzf "${_UI_FZF_CHROME[@]}" --border-label ' workspaces ' \
      --delimiter '\t' --with-nth 1 --accept-nth 2 \
      --prompt 'go> ' \
      --preview "source ${_UI_LIB}; _ui_git_preview {3}"
) || exit 0
[[ -n $ws ]] || exit 0

herdr workspace focus "$ws" >/dev/null || die "herdr could not focus $ws"
