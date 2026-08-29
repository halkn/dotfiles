#!/usr/bin/env zsh
# Tests for the go listing in workflows/wk.zsh: what a row reads as, which rows
# survive the merge of herdr's workspaces with the worktrees on disk, and the
# order they come out in. herdr is stubbed, so this runs on a machine without
# it. Run with `mise run test:zsh`.

set -uo pipefail

source "${0:A:h}/../workflows/wk.zsh"

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

scratch=$(mktemp -d "${TMPDIR:-/tmp}/wk-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT

wt=$scratch/wt
repos=$scratch/repos
mkdir -p "$wt"/halkn/dotfiles/{main,feat-a} "$wt"/halkn/trepo/fix-b \
  "$repos"/github.com/halkn/dotfiles/.git

export WT_ROOT=$wt REPO_ROOT=$repos

# The rows as the picker sees them: the display column alone, which is what the
# ordering is on.
displays() { _wk_go_rows | cut -f1 | sed 's/  */ /g;s/ $//'; }

# 1. Without herdr there are only worktrees, ordered by repository then branch.
_sess_workspace_rows() { return 0; }
check 'worktrees only' \
  'halkn/dotfiles feat-a wt
halkn/dotfiles main wt
halkn/trepo fix-b wt' \
  "$(displays)"

# 2. A worktree a workspace is already on is one row, not two: both would land
# in the same workspace, and the workspace row carries herdr's number and label.
_sess_workspace_rows() {
  printf 'w1\t1\tdotfiles\t%s\n' "$repos/github.com/halkn/dotfiles"
  printf 'w2\t2\tfeat-a\t%s\n' "$wt/halkn/dotfiles/feat-a"
  printf 'w3\t3\t~\t\n'
}
check 'merged' \
  'halkn/dotfiles ws [1] dotfiles
halkn/dotfiles feat-a ws [2] feat-a
halkn/dotfiles main wt
halkn/trepo fix-b wt
~ ws [3]' \
  "$(displays)"

# The target column is what Enter acts on: a workspace is focused, a worktree is
# opened by path.
check 'targets' \
  "workspace:w1
workspace:w2
$wt/halkn/dotfiles/main
$wt/halkn/trepo/fix-b
workspace:w3" \
  "$(_wk_go_rows | cut -f2)"

# 3. herdr does not have to have labelled a workspace, and a workspace does not
# have to sit on a checkout. An empty field must not shift the columns after it,
# which is what `read` would do with two adjacent tabs - the row would be named
# after the raw path and its worktree would come back as a second row.
_sess_workspace_rows() { printf 'w1\t1\t\t%s\n' "$wt/halkn/dotfiles/feat-a"; }
check 'empty label' \
  'halkn/dotfiles feat-a ws [1]
halkn/dotfiles main wt
halkn/trepo fix-b wt' \
  "$(displays)"

# 4. Nothing anywhere is an empty listing, not a row of empty columns.
_sess_workspace_rows() { return 0; }
check 'nothing' '' "$(WT_ROOT=$scratch/nowhere _wk_go_rows)"

if ((failures > 0)); then
  print -u2 "wk_test: $failures assertion(s) failed"
  exit 1
fi
print 'wk_test: ok'
