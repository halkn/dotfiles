#!/usr/bin/env zsh
# Tests for the pure part of the `wt` navigator: folding workspaces, worktrees
# and repositories onto one row per checkout. Run with `mise run test:zsh`.

set -uo pipefail

source "${0:A:h}/../workflows/worktree.zsh"

typeset -i failures=0

check() {
  local label=$1 want=$2 got=$3
  if [[ $got != "$want" ]]; then
    print -u2 "FAIL $label"
    print -u2 "  want: ${want//$'\n'/ | }"
    print -u2 "  got : ${got//$'\n'/ | }"
    ((failures++))
  fi
}

# <kind>\t<checkout path>\t<target>\t<label> in, `<label>\t<kind>:<target>` out.
rows() {
  local row
  for row in "$@"; do
    print -r -- "$row"
  done
}

# A checkout that is open as a workspace must not also appear as a worktree or
# as a repository: the workspace row is the one that can be focused.
check 'one row per checkout' \
  $'ws-a\tworkspace:1' \
  "$(rows \
    $'workspace\t/w/a\t1\tws-a' \
    $'worktree\t/w/a\t/w/a\twt-a' \
    $'repo\t/w/a\t/w/a\trepo-a' | _wt_nav_merge)"

# Priority is by kind, not by input order.
check 'workspace wins over worktree regardless of order' \
  $'ws-a\tworkspace:1' \
  "$(rows \
    $'repo\t/w/a\t/w/a\trepo-a' \
    $'worktree\t/w/a\t/w/a\twt-a' \
    $'workspace\t/w/a\t1\tws-a' | _wt_nav_merge)"

check 'worktree wins over repo' \
  $'wt-a\tworktree:/w/a' \
  "$(rows \
    $'repo\t/w/a\t/w/a\trepo-a' \
    $'worktree\t/w/a\t/w/a\twt-a' | _wt_nav_merge)"

# Output order is workspaces, then worktrees, then repositories, keeping the
# input order inside each kind.
check 'ordered by kind, stable within a kind' \
  $'ws-a\tworkspace:1\nws-b\tworkspace:2\nwt-c\tworktree:/w/c\nrepo-d\trepo:/w/d' \
  "$(rows \
    $'repo\t/w/d\t/w/d\trepo-d' \
    $'worktree\t/w/c\t/w/c\twt-c' \
    $'workspace\t/w/a\t1\tws-a' \
    $'workspace\t/w/b\t2\tws-b' | _wt_nav_merge)"

# A workspace with no checkout (created from an arbitrary cwd, or none at all)
# has nothing to fold onto, so every one of them survives.
check 'path-less workspaces are all kept' \
  $'ws-a\tworkspace:1\nws-b\tworkspace:2' \
  "$(rows \
    $'workspace\t\t1\tws-a' \
    $'workspace\t\t2\tws-b' | _wt_nav_merge)"

check 'empty input' '' "$(printf '' | _wt_nav_merge)"

# A row without a target cannot be opened, so it is dropped instead of being
# offered as an unusable choice.
check 'rows without a target are dropped' \
  $'wt-a\tworktree:/w/a' \
  "$(rows \
    $'worktree\t/w/b\t\twt-b' \
    $'worktree\t/w/a\t/w/a\twt-a' | _wt_nav_merge)"

# git reports checkout paths with every symlink resolved (/private/tmp, not
# /tmp), so a repository listed through an unresolved path has to be folded onto
# the same row rather than showing up twice.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/worktree-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/real"
ln -s "$scratch/real" "$scratch/link"

check 'keys are resolved before folding' \
  $'wt-a\tworktree:'"$scratch/real" \
  "$(rows \
    "worktree	$scratch/real	$scratch/real	wt-a" \
    "repo	$scratch/link	$scratch/link	repo-a" | _wt_nav_resolve | _wt_nav_merge)"

# A path that does not exist cannot be resolved; keeping it as it is leaves the
# row usable (`_wt_preview` reports a missing checkout).
check 'unresolvable keys are kept' \
  $'wt-a\tworktree:/nope/a' \
  "$(rows $'worktree\t/nope/a\t/nope/a\twt-a' | _wt_nav_resolve | _wt_nav_merge)"

if ((failures > 0)); then
  print -u2 "worktree_test: $failures assertion(s) failed"
  exit 1
fi
print 'worktree_test: ok'
