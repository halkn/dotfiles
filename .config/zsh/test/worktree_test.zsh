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

# Two workspaces on one checkout are two places to go - a second workspace on
# the same repository is exactly what parallel work looks like - so folding only
# ever removes the worktree and repository rows behind them.
check 'workspaces on the same checkout are all kept' \
  $'ws-a\tworkspace:1\nws-b\tworkspace:2' \
  "$(rows \
    $'workspace\t/w/a\t1\tws-a' \
    $'workspace\t/w/a\t2\tws-b' \
    $'repo\t/w/a\t/w/a\trepo-a' | _wt_nav_merge)"

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

# A workspace with no checkout has an empty key, and tab is IFS whitespace in
# zsh: splitting on it would fold the empty field away and shift the target
# into it, which is what dropped such workspaces from the picker.
check 'an empty key survives resolution' \
  $'ws-a\tworkspace:1' \
  "$(rows $'workspace\t\t1\tws-a' | _wt_nav_resolve | _wt_nav_merge)"

# A workspace is recognised by the directory its panes are in, which can be
# anywhere below the checkout. Folding still has to happen on the checkout, or
# the repository row would come back as soon as a pane cd'd into a subdirectory.
git -C "$scratch/real" init --quiet
mkdir -p "$scratch/real/sub"

check 'a directory below a checkout folds onto the checkout' \
  $'ws-a\tworkspace:1' \
  "$(rows \
    "workspace	$scratch/real/sub	1	ws-a" \
    "repo	$scratch/real	$scratch/real	repo-a" | _wt_nav_resolve | _wt_nav_merge)"

check 'an empty trailing field survives resolution' \
  $'worktree\t/nope/a\twt-a\t' \
  "$(rows $'worktree\t/nope/a\twt-a\t' | _wt_nav_resolve)"

# The herdr answers as they come back from the socket (herdr 0.8.2): a workspace
# made from a worktree, one opened on a plain directory, and the worktree list
# that holds the branch of the first.
ws_json='{"result":{"workspaces":[
  {"number":1,"label":"dotfiles","workspace_id":"w14","worktree":{"checkout_path":"/w/dotfiles","repo_name":"dotfiles"}},
  {"number":2,"label":"it-cert-study","workspace_id":"w17","worktree":null}
]}}'
pane_json='{"result":{"panes":[
  {"pane_id":"p1","workspace_id":"w17","cwd":"/w/it-cert-study","focused":false},
  {"pane_id":"p2","workspace_id":"w17","cwd":"/w/it-cert-study/docs","focused":true}
]}}'
wt_json='{"result":{"worktrees":[
  {"path":"/w/dotfiles","branch":"main","label":"dotfiles","open_workspace_id":"w14"},
  {"path":"/w/wt/topic","branch":"topic","label":"dotfiles","open_workspace_id":null}
]}}'

# A workspace with no worktree takes the cwd of its focused pane, which is what
# gives every row a directory to be recognised by.
check 'workspace rows carry a directory and a branch' \
  "$(rows \
    $'workspace\t/w/dotfiles\tw14\t[1] dotfiles\tmain\t/w/dotfiles' \
    $'workspace\t/w/it-cert-study/docs\tw17\t[2] it-cert-study\t\t/w/it-cert-study/docs')" \
  "$(print -r -- "$ws_json" | _wt_nav_workspace_filter "$pane_json" "$wt_json")"

# Without the pane and worktree answers the rows still have to be usable.
check 'workspace rows survive missing pane and worktree answers' \
  "$(rows \
    $'workspace\t/w/dotfiles\tw14\t[1] dotfiles\t\t/w/dotfiles' \
    $'workspace\t\tw17\t[2] it-cert-study\t\t')" \
  "$(print -r -- "$ws_json" | _wt_nav_workspace_filter null null)"

check 'worktree rows' \
  "$(rows \
    $'worktree\t/w/dotfiles\t/w/dotfiles\tdotfiles\tmain\t/w/dotfiles' \
    $'worktree\t/w/wt/topic\t/w/wt/topic\tdotfiles\ttopic\t/w/wt/topic')" \
  "$(print -r -- "$wt_json" | _wt_nav_worktree_filter)"

# End to end: the worktree behind a workspace and the repository behind a plain
# workspace both fold away, and both workspaces keep their directory.
check 'the herdr answers fold into one row per place' \
  "$(rows \
    $'ws   [1] dotfiles                       main                       /w/dotfiles\tworkspace:w14' \
    $'ws   [2] it-cert-study                  -                          /w/it-cert-study\tworkspace:w17' \
    $'wt   dotfiles                           topic                      /w/wt/topic\tworktree:/w/wt/topic')" \
  "$(
    {
      print -r -- "$ws_json" \
        | _wt_nav_workspace_filter "${pane_json//\/docs/}" "$wt_json"
      print -r -- "$wt_json" | _wt_nav_worktree_filter
      printf 'repo\t/w/it-cert-study\t/w/it-cert-study\thalkn/it-cert-study\t\t/w/it-cert-study\n'
    } | _wt_nav_format | _wt_nav_merge
  )"

if ((failures > 0)); then
  print -u2 "worktree_test: $failures assertion(s) failed"
  exit 1
fi
print 'worktree_test: ok'
