#!/bin/zsh
set -euo pipefail

# ghq リポジトリの一覧・preview は repo（zsh 関数）に集約し、ここでは再実装しない。
repo_lib=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/repo.zsh
[[ -r $repo_lib ]] || {
  print -u2 "herdr-repo-workspace: $repo_lib not found"
  exit 1
}
source "$repo_lib"

_repo_available || exit 1

dir=$(_repo_pick "${1:-}") || exit 0
[[ -n $dir ]] || exit 0

# --focus は既定ではないので明示する（herdr 0.8.0）。
herdr workspace create --cwd "$dir" --label "${dir:t}" --focus
