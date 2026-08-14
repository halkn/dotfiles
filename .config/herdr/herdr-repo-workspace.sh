#!/bin/zsh
set -euo pipefail

# Listing and previewing repositories lives in `repo`; do not reimplement either here.
repo_lib=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows/repo.zsh
[[ -r $repo_lib ]] || {
  print -u2 "herdr-repo-workspace: $repo_lib not found"
  exit 1
}
source "$repo_lib"

_repo_fzf_available || exit 1

dir=$(_repo_pick "${1:-}") || exit 0
[[ -n $dir ]] || exit 0

# --focus is not the default (herdr 0.8.0).
herdr workspace create --cwd "$dir" --label "${dir:t}" --focus
