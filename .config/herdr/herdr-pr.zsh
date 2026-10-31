#!/bin/zsh
# alt+p in herdr: pick an open pull request of the focused workspace's
# repository and open its worktree with `hw pr`, on GitHub or Azure DevOps.
set -uo pipefail

ui_lib=${XDG_CONFIG_HOME:-$HOME/.config}/herdr/ui.zsh
if [[ -r $ui_lib ]]; then
  source "$ui_lib"
fi

whence _ui_require >/dev/null || {
  print -u2 "herdr-pr: $ui_lib not found"
  print -n 'press any key '
  read -rsk1 || true
  exit 1
}
_ui_require herdr-pr hw fzf || _ui_die

dir=$(hw focused) || _ui_die
cd "$dir" || _ui_die herdr-pr "cannot enter $dir"
rows=$(hw prs) || _ui_die
[[ -n $rows ]] || _ui_die herdr-pr 'no open pull requests'

# A cancelled picker is not a failure.
row=$(
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" --border-label ' pull request ' \
      --delimiter '\t' --with-nth 1 --prompt 'pr> '
) || exit 0
[[ -n $row ]] || exit 0
hw pr "${row#*$'\t'}" || _ui_die
