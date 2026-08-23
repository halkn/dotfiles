#!/usr/bin/env zsh
# Tests for the pure part of the navigator: reading the herdr answers,
# resolving the checkout behind a row, and folding workspaces, worktrees and
# repositories onto one row per checkout. Run with `mise run test:zsh`.

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

# A checkout that is open as a workspace must not also appear as a worktree or
# as a repository: the workspace row is the one that can be focused.
check 'one row per checkout' \
  $'ws-a\tworkspace:1\t/w/a' \
  "$(rows \
    $'workspace\t/w/a\t1\tws-a' \
    $'worktree\t/w/a\t/w/a\twt-a' \
    $'repo\t/w/a\t/w/a\trepo-a' | _nav_merge)"

# Priority is by kind, not by input order.
check 'workspace wins over worktree regardless of order' \
  $'ws-a\tworkspace:1\t/w/a' \
  "$(rows \
    $'repo\t/w/a\t/w/a\trepo-a' \
    $'worktree\t/w/a\t/w/a\twt-a' \
    $'workspace\t/w/a\t1\tws-a' | _nav_merge)"

check 'worktree wins over repo' \
  $'wt-a\tworktree:/w/a\t/w/a' \
  "$(rows \
    $'repo\t/w/a\t/w/a\trepo-a' \
    $'worktree\t/w/a\t/w/a\twt-a' | _nav_merge)"

# Output order is workspaces, then worktrees, then repositories, keeping the
# input order inside each kind.
check 'ordered by kind, stable within a kind' \
  "$(rows \
    $'ws-a\tworkspace:1\t/w/a' \
    $'ws-b\tworkspace:2\t/w/b' \
    $'wt-c\tworktree:/w/c\t/w/c' \
    $'repo-d\trepo:/w/d\t/w/d')" \
  "$(rows \
    $'repo\t/w/d\t/w/d\trepo-d' \
    $'worktree\t/w/c\t/w/c\twt-c' \
    $'workspace\t/w/a\t1\tws-a' \
    $'workspace\t/w/b\t2\tws-b' | _nav_merge)"

# Two workspaces on one checkout are two places to go - a second workspace on
# the same repository is exactly what parallel work looks like - so folding only
# ever removes the worktree and repository rows behind them.
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

# herdr and git both answer for a worktree herdr has open, and the listing asks
# both so that a checkout herdr does not manage still shows up. The row that
# survives is herdr's, whose target it can act on.
check 'the same worktree from both sources folds onto herdr' \
  $'wt-herdr\tworktree:/w/a\t/w/a' \
  "$(rows \
    $'worktree\t/w/a\t/w/a\twt-herdr' \
    $'worktree\t/w/a\t/w/a\twt-git' | _nav_merge)"

# A row without a target cannot be opened, so it is dropped instead of being
# offered as an unusable choice.
check 'rows without a target are dropped' \
  $'wt-a\tworktree:/w/a\t/w/a' \
  "$(rows \
    $'worktree\t/w/b\t\twt-b' \
    $'worktree\t/w/a\t/w/a\twt-a' | _nav_merge)"

# ── resolve ──────────────────────────────────────────
# Six fields in, six out: the key becomes the checkout the row belongs to, and
# the branch and the directory shown are filled in from it.

scratch=$(mktemp -d "${TMPDIR:-/tmp}/worktree-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/real/sub"
ln -s "$scratch/real" "$scratch/link"
git -C "$scratch/real" init --quiet --initial-branch=topic
git -C "$scratch/real" -c user.email=t@e -c user.name=t commit --quiet --allow-empty -m init

# git reports checkout paths with every symlink resolved (/private/tmp, not
# /tmp), so a repository listed through an unresolved path has to fold onto the
# same row rather than showing up twice. A row is also recognised by the
# directory its panes sit in, which can be anywhere below the checkout.
check 'a directory below a checkout resolves to the checkout' \
  "$(rows "workspace	${scratch:A}/real	1	ws-a	topic	${scratch:A}/real")" \
  "$(rows "workspace	$scratch/link/sub	1	ws-a		" | _nav_resolve)"

# A main checkout answers both questions without a git process: it is a work
# tree root by definition, and its branch is the ref in .git/HEAD.
check '_nav_head_branch reads a ref' topic "$(_nav_head_branch "$scratch/real/.git/HEAD")"
check '_nav_head_branch on a detached HEAD' '(detached)' \
  "$(print -r -- 'aa53f4c69f0b3e0dcb2a4e21ba4dfd9b6d51e30f' >"$scratch/HEAD-detached" &&
    _nav_head_branch "$scratch/HEAD-detached")"
check '_nav_head_branch on a missing file' '' "$(_nav_head_branch "$scratch/nope/HEAD")"

# The branch is only asked for when the answer that produced the row had none:
# herdr already reports it for a worktree, and asking again would be a second
# process per row. The target is left exactly as it came, since it is handed
# back to herdr, which matches it against its own spelling of the path.
check 'a branch that is already known is kept' \
  "$(rows "worktree	${scratch:A}/real	$scratch/real	wt-a	given	${scratch:A}/real")" \
  "$(rows "worktree	$scratch/real	$scratch/real	wt-a	given	$scratch/real" | _nav_resolve)"

# A path that does not exist cannot be resolved; keeping it as it is leaves the
# row usable (`_wt_preview` reports a missing checkout).
check 'unresolvable keys are kept' \
  "$(rows $'worktree\t/nope/a\t/nope/a\twt-a\t\t/nope/a')" \
  "$(rows $'worktree\t/nope/a\t/nope/a\twt-a\t\t/nope/a' | _nav_resolve)"

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
# the cwd of its focused pane - that is what gives every row a directory.
check 'workspace rows carry a directory and a branch' \
  "$(rows \
    $'workspace\t/w/dotfiles\tw14\t[1] dotfiles\tmain\t/w/dotfiles' \
    $'workspace\t/w/it-cert-study/docs\tw17\t[2] it-cert-study\t\t/w/it-cert-study/docs')" \
  "$(print -r -- "$ws_json" | _nav_workspace_filter "$pane_json" "$wt_json")"

# Without the pane and worktree answers the rows still have to be usable.
check 'workspace rows survive missing pane and worktree answers' \
  "$(rows \
    $'workspace\t/w/dotfiles\tw14\t[1] dotfiles\t\t/w/dotfiles' \
    $'workspace\t\tw17\t[2] it-cert-study\t\t')" \
  "$(print -r -- "$ws_json" | _nav_workspace_filter null null)"

check 'worktree rows' \
  "$(rows \
    $'worktree\t/w/dotfiles\t/w/dotfiles\tdotfiles\tmain\t/w/dotfiles' \
    $'worktree\t/w/wt/topic\t/w/wt/topic\tdotfiles\ttopic\t/w/wt/topic')" \
  "$(print -r -- "$wt_json" | _nav_worktree_filter)"

# End to end, with the checkouts on disk so that resolution has something to
# answer: the repository row behind the plain workspace folds away, and every
# row carries the same three columns.
mkdir -p "$scratch/it-cert-study/docs"
git -C "$scratch/it-cert-study" init --quiet --initial-branch=study
git -C "$scratch/it-cert-study" -c user.email=t@e -c user.name=t commit --quiet --allow-empty -m init

check 'the herdr answers fold into one row per place' \
  "$(rows \
    "ws   [2] it-cert-study                  study                      ${scratch:A}/it-cert-study	workspace:w17	${scratch:A}/it-cert-study" \
    "wt   real                               topic                      ${scratch:A}/real	worktree:$scratch/real	${scratch:A}/real")" \
  "$(
    {
      printf 'workspace\t%s\tw17\t[2] it-cert-study\t\t%s\n' \
        "$scratch/it-cert-study/docs" "$scratch/it-cert-study"
      printf 'worktree\t%s\t%s\treal\ttopic\t%s\n' "$scratch/real" "$scratch/real" "$scratch/real"
      printf 'repo\t%s\t%s\thalkn/it-cert-study\t\t%s\n' \
        "$scratch/it-cert-study" "$scratch/it-cert-study" "$scratch/it-cert-study"
    } | _nav_resolve | _nav_format | _nav_merge
  )"

if ((failures > 0)); then
  print -u2 "nav_test: $failures assertion(s) failed"
  exit 1
fi
print 'nav_test: ok'
