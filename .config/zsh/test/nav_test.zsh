#!/usr/bin/env zsh
# Tests for the pure part of the navigator: reading the trepo and herdr answers,
# resolving the checkout behind a workspace, and folding the two onto one row
# per checkout. Run with `mise run test:zsh`.

set -uo pipefail

source "${0:A:h}/../workflows/worktree.zsh"
source "${0:A:h}/../workflows/nav.zsh"

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

rows() {
  local row
  for row in "$@"; do
    print -r -- "$row"
  done
}

# ── merge ────────────────────────────────────────────
# `<kind> <key> <target> <label>` in, `<label> <kind>:<target> <key>` out.

# A checkout that is open as a workspace must not also appear as a checkout row:
# the workspace row is the one that can be focused.
check 'one row per checkout' \
  $'ws-a\tworkspace:1\t/w/a' \
  "$(rows \
    $'workspace\t/w/a\t1\tws-a' \
    $'worktree\t/w/a\t/w/a\twt-a' | _nav_merge)"

# Priority is by kind, not by input order.
check 'workspace wins over a checkout regardless of order' \
  $'ws-a\tworkspace:1\t/w/a' \
  "$(rows \
    $'worktree\t/w/a\t/w/a\twt-a' \
    $'workspace\t/w/a\t1\tws-a' | _nav_merge)"

# A main checkout is claimed the same way a worktree is: what folds a row away
# is the workspace standing on its directory, not which kind of checkout it is.
check 'a workspace claims a main checkout too' \
  $'ws-a\tworkspace:1\t/w/a' \
  "$(rows \
    $'repo\t/w/a\t/w/a\trepo-a' \
    $'workspace\t/w/a\t1\tws-a' | _nav_merge)"

# Workspaces first, then the checkouts in the order trepo listed them: a
# repository's main checkout ahead of its own worktrees, which is what keeps the
# rows of one repository together instead of split by kind.
check 'workspaces first, then trepo order' \
  "$(rows \
    $'ws-a\tworkspace:1\t/w/a' \
    $'repo-b\trepo:/w/b\t/w/b' \
    $'wt-b1\tworktree:/w/b1\t/w/b1' \
    $'repo-c\trepo:/w/c\t/w/c')" \
  "$(rows \
    $'repo\t/w/b\t/w/b\trepo-b' \
    $'worktree\t/w/b1\t/w/b1\twt-b1' \
    $'repo\t/w/c\t/w/c\trepo-c' \
    $'workspace\t/w/a\t1\tws-a' | _nav_merge)"

# Two workspaces on one checkout are two places to go - a second workspace on
# the same repository is exactly what parallel work looks like - so folding only
# ever removes the checkout row behind them.
check 'workspaces on the same checkout are all kept' \
  "$(rows $'ws-a\tworkspace:1\t/w/a' $'ws-b\tworkspace:2\t/w/a')" \
  "$(rows \
    $'workspace\t/w/a\t1\tws-a' \
    $'workspace\t/w/a\t2\tws-b' \
    $'repo\t/w/a\t/w/a\trepo-a' | _nav_merge)"

# A workspace with no checkout (created from an arbitrary cwd, or none at all)
# has nothing to fold onto, so every one of them survives.
check 'checkout-less workspaces are all kept' \
  "$(rows $'ws-a\tworkspace:1\t' $'ws-b\tworkspace:2\t')" \
  "$(rows \
    $'workspace\t\t1\tws-a' \
    $'workspace\t\t2\tws-b' | _nav_merge)"

check 'empty input' '' "$(printf '' | _nav_merge)"

# One directory can only be one row even if a source repeats it.
check 'a repeated checkout folds onto the first row' \
  $'wt-first\tworktree:/w/a\t/w/a' \
  "$(rows \
    $'worktree\t/w/a\t/w/a\twt-first' \
    $'worktree\t/w/a\t/w/a\twt-second' | _nav_merge)"

# A row without a target cannot be opened, so it is dropped instead of being
# offered as an unusable choice.
check 'rows without a target are dropped' \
  $'wt-a\tworktree:/w/a\t/w/a' \
  "$(rows \
    $'worktree\t/w/b\t\twt-b' \
    $'worktree\t/w/a\t/w/a\twt-a' | _nav_merge)"

# ── the trepo answer ─────────────────────────────────
# As `trepo list --json` returns it (trepo v0.5.0): a repository's main checkout
# and one of its worktrees, in trepo's own order.

trepo_json='[
  {"repo":"halkn/dotfiles","host":"github.com","owner":"halkn","name":"dotfiles",
   "branch":"main","path":"/w/dotfiles","kind":"repo","flags":["current","merged"]},
  {"repo":"halkn/dotfiles","host":"github.com","owner":"halkn","name":"dotfiles",
   "branch":"topic","path":"/w/wt/topic","kind":"worktree","flags":["dirty"]},
  {"repo":"halkn/it-cert-study","host":"github.com","owner":"halkn","name":"it-cert-study",
   "branch":"","path":"/w/study","kind":"worktree","flags":["detached"]}
]'

# `kind` is what decides whether Enter opens the row as itself or as a new
# workspace, and it is the one field the plain text output does not carry.
# The sixth field is filled in, which is what keeps _nav_resolve off these rows.
check 'checkout rows carry the kind, the slug and a resolved path' \
  "$(rows \
    $'repo\t/w/dotfiles\t/w/dotfiles\thalkn/dotfiles\tmain\t/w/dotfiles' \
    $'worktree\t/w/wt/topic\t/w/wt/topic\thalkn/dotfiles\ttopic\t/w/wt/topic' \
    $'worktree\t/w/study\t/w/study\thalkn/it-cert-study\t\t/w/study')" \
  "$(print -r -- "$trepo_json" | _nav_checkout_filter)"

check 'an empty trepo answer is an empty listing' '' \
  "$(print -r -- '[]' | _nav_checkout_filter)"

# ── resolve ──────────────────────────────────────────
# Six fields in, six out. Only a row that arrived without a checkout path is
# looked up; everything trepo produced is already resolved.

scratch=$(mktemp -d "${TMPDIR:-/tmp}/worktree-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/real/sub"
ln -s "$scratch/real" "$scratch/link"
git -C "$scratch/real" init --quiet --initial-branch=topic
git -C "$scratch/real" -c user.email=t@e -c user.name=t commit --quiet --allow-empty -m init

# A workspace is recognised by the directory its panes sit in, which can be
# anywhere below the checkout. git reports checkout paths with every symlink
# resolved (/private/tmp, not /tmp), and so does trepo, so a workspace reached
# through an unresolved path still has to fold onto the same row.
check 'a directory below a checkout resolves to the checkout' \
  "$(rows "workspace	${scratch:A}/real	1	ws-a	topic	${scratch:A}/real")" \
  "$(rows "workspace	$scratch/link/sub	1	ws-a		" | _nav_resolve)"

# A branch herdr already reported for a workspace made from a worktree is kept,
# so the lookup below costs one git process rather than two.
check 'a branch that is already known is kept' \
  "$(rows "workspace	${scratch:A}/real	1	ws-a	given	${scratch:A}/real")" \
  "$(rows "workspace	$scratch/link/sub	1	ws-a	given	" | _nav_resolve)"

# A row that already names its checkout is passed through untouched: trepo
# resolved it, and re-asking git would cost a process for every row in the list.
check 'a row that knows its checkout is left alone' \
  "$(rows $'worktree\t/w/a\t/w/a\thalkn/x\ttopic\t/w/a')" \
  "$(rows $'worktree\t/w/a\t/w/a\thalkn/x\ttopic\t/w/a' | _nav_resolve)"

# A path that does not exist cannot be resolved; keeping it as it is leaves the
# row usable (`_wt_preview` reports a missing checkout).
check 'unresolvable keys are kept' \
  "$(rows $'workspace\t/nope/a\t1\tws-a\t\t/nope/a')" \
  "$(rows $'workspace\t/nope/a\t1\tws-a\t\t' | _nav_resolve)"

# A workspace with no checkout has an empty key, and tab is IFS whitespace in
# zsh: splitting on it would fold the empty field away and shift the target
# into it, which is what dropped such workspaces from the picker.
check 'an empty key survives resolution' \
  "$(rows $'workspace\t\t1\tws-a\t\t')" \
  "$(rows $'workspace\t\t1\tws-a\t\t' | _nav_resolve)"

# ── the herdr answers ────────────────────────────────
# As they come back from the socket (herdr 0.8.2): a workspace made from a
# worktree, one opened on a plain directory, and the worktree list that holds
# the branch of the first.
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

# A workspace reports no directory of its own, so one without a worktree takes
# the cwd of its focused pane. The sixth field stays empty either way: only
# _nav_resolve can say which checkout that directory belongs to.
check 'workspace rows carry a directory and a branch' \
  "$(rows \
    $'workspace\t/w/dotfiles\tw14\t[1] dotfiles\tmain\t' \
    $'workspace\t/w/it-cert-study/docs\tw17\t[2] it-cert-study\t\t')" \
  "$(print -r -- "$ws_json" | _nav_workspace_filter "$pane_json" "$wt_json")"

# Without the pane and worktree answers the rows still have to be usable.
check 'workspace rows survive missing pane and worktree answers' \
  "$(rows \
    $'workspace\t/w/dotfiles\tw14\t[1] dotfiles\t\t' \
    $'workspace\t\tw17\t[2] it-cert-study\t\t')" \
  "$(print -r -- "$ws_json" | _nav_workspace_filter null null)"

# End to end, with the checkouts on disk so that resolution has something to
# answer: the trepo row behind the workspace folds away, and every row carries
# the same three columns.
mkdir -p "$scratch/it-cert-study/docs"
git -C "$scratch/it-cert-study" init --quiet --initial-branch=study
git -C "$scratch/it-cert-study" -c user.email=t@e -c user.name=t commit --quiet --allow-empty -m init

check 'the two answers fold into one row per place' \
  "$(rows \
    "ws   [2] it-cert-study                  study                      ${scratch:A}/it-cert-study	workspace:w17	${scratch:A}/it-cert-study" \
    "wt   halkn/real                         topic                      ${scratch:A}/real	worktree:${scratch:A}/real	${scratch:A}/real")" \
  "$(
    {
      printf 'workspace\t%s\tw17\t[2] it-cert-study\t\t\n' "$scratch/it-cert-study/docs"
      printf 'repo\t%s\t%s\thalkn/it-cert-study\tstudy\t%s\n' \
        "${scratch:A}/it-cert-study" "${scratch:A}/it-cert-study" "${scratch:A}/it-cert-study"
      printf 'worktree\t%s\t%s\thalkn/real\ttopic\t%s\n' \
        "${scratch:A}/real" "${scratch:A}/real" "${scratch:A}/real"
    } | _nav_resolve | _nav_format | _nav_merge
  )"

if ((failures > 0)); then
  print -u2 "nav_test: $failures assertion(s) failed"
  exit 1
fi
print 'nav_test: ok'
