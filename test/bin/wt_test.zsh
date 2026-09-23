#!/usr/bin/env zsh
# Tests for bin/wt: where a worktree lands, what the listing serves, and what
# new / rm / prune leave behind. It is an executable rather than a sourced
# function, so everything here runs it as a subprocess against a scratch
# repository and reads stdout. gh is a stub on PATH; `wt pr` is covered only up
# to what the stub answers. Run with `mise run test:scripts`.

set -uo pipefail

wt_bin=${0:A:h}/../../bin/wt

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

fail() {
  print -u2 "FAIL $1"
  ((failures++))
}

[[ -x $wt_bin ]] || {
  print -u2 "wt_test: $wt_bin is not executable"
  exit 1
}

wt() { "$wt_bin" "$@"; }

# ── root ─────────────────────────────────────────────

check 'root' /w/wt "$(WT_ROOT=/w/wt wt root)"
check 'root (trailing slash)' /w/wt "$(WT_ROOT=/w/wt/ wt root)"
check 'root (tilde)' "$HOME/wt" "$(WT_ROOT='~/wt' wt root)"

# The fallback is herdr's own `[worktrees] directory`.
herdr_dir=$(sed -n 's/^directory = "\(.*\)"$/\1/p' "${0:A:h}/../../.config/herdr/config.toml")
check 'root (unset)' "${herdr_dir/#\~/$HOME}" \
  "$(unset WT_ROOT && XDG_DATA_HOME=$HOME/.local/share wt root)"

# ── fixture ──────────────────────────────────────────

scratch=$(mktemp -d "${TMPDIR:-/tmp}/wt-test.XXXXXX") || exit 1
scratch=${scratch:A}
trap 'rm -rf -- "$scratch"' EXIT

# git reads the global config through $XDG_CONFIG_HOME before $HOME, and here
# that is this repository's tracked .config/git/config.
export HOME=$scratch/home XDG_CONFIG_HOME=$scratch/home/.config
export GIT_CONFIG_GLOBAL=$scratch/home/.gitconfig GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
git config --global user.name wt-test
git config --global user.email wt-test@example.invalid
git config --global init.defaultBranch main

export WT_ROOT=$scratch/wt
main=$scratch/repos/github.com/owner/proj
origin=$scratch/origin.git

git init -q --bare "$origin"
git init -q "$main"
git -C "$main" commit -q --allow-empty -m init
git -C "$main" remote add origin "$origin"
git -C "$main" push -q -u origin main
git -C "$main" branch local-only
# A branch that exists only on origin, as a teammate's would.
git -C "$main" branch remote-only
git -C "$main" push -q origin remote-only
git -C "$main" branch -D -q remote-only
git -C "$main" update-ref -d refs/remotes/origin/remote-only

# A stub gh: `pr list --state merged --head <b>` answers the head oid of each
# merged PR recorded in $STUB_MERGED_DIR/<b>, any other `pr list` answers
# $STUB_PR_ROWS, `pr view` answers $STUB_PR_VIEW, and `pr checkout` makes the
# branch.
stub=$scratch/stub
mkdir -p "$stub"
cat >"$stub/gh" <<'STUB'
#!/bin/zsh
args=("$@")
case "$1 $2" in
  'pr list')
    head=${args[(i)--head]}
    if ((head > ${#args})); then
      print -r -- "${STUB_PR_ROWS:-}"
      exit
    fi
    b=${args[head + 1]}
    [[ -f ${STUB_MERGED_DIR:-/nonexistent}/$b ]] && cat -- "$STUB_MERGED_DIR/$b"
    ;;
  'pr view')
    print -r -- "${STUB_PR_VIEW:-}"
    ;;
  'pr checkout')
    git checkout -q -b pr-branch
    ;;
esac
STUB
chmod +x "$stub/gh"
export PATH=$stub:$PATH

in_main() {
  (cd -- "$main" && "$wt_bin" "$@")
}

status_of() {
  "$@" >/dev/null 2>&1
  print $?
}

# ── path / new ───────────────────────────────────────

# The directory is <owner>/<repo> of the main checkout plus the branch as one
# path segment.
check 'path' "$WT_ROOT/owner/proj/feature-a" "$(in_main path feature/a)"

got=$(in_main new topic 2>/dev/null)
check 'new (fresh branch)' "$WT_ROOT/owner/proj/topic" "$got"
check 'new (fresh branch is checked out)' topic \
  "$(git -C "$WT_ROOT/owner/proj/topic" branch --show-current 2>/dev/null)"

check 'new (existing worktree)' "$WT_ROOT/owner/proj/topic" "$(in_main new topic 2>/dev/null)"

in_main new local-only >/dev/null 2>&1
check 'new (local branch)' local-only \
  "$(git -C "$WT_ROOT/owner/proj/local-only" branch --show-current 2>/dev/null)"

in_main new remote-only >/dev/null 2>&1
check 'new (remote-only branch tracks origin)' origin/remote-only \
  "$(git -C "$WT_ROOT/owner/proj/remote-only" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"

in_main new based main >/dev/null 2>&1
check 'new (base)' "$(git -C "$main" rev-parse main)" \
  "$(git -C "$WT_ROOT/owner/proj/based" rev-parse HEAD 2>/dev/null)"

# A base always means a new branch, so an existing one is an error, and so is a
# worktree already standing where the new one would go.
in_main new main main >/dev/null 2>&1 && fail 'new (base on an existing branch) should fail'
in_main new topic main >/dev/null 2>&1 && fail 'new (base on an existing worktree) should fail'

# `/` folds to `-` in the directory, so feat/x and feat-x share one. Handing back
# the other branch's worktree would open the wrong branch without a word.
in_main new feat-x >/dev/null 2>&1
in_main new feat/x >/dev/null 2>&1 && fail 'new (directory holds another branch) should fail'

# An origin that cannot be reached still leaves what is known of it: the branch
# is tracked from the last fetch rather than forked afresh from HEAD.
git -C "$main" branch offline
git -C "$main" push -q origin offline
git -C "$main" branch -D -q offline
git -C "$main" remote set-url origin "$scratch/unreachable.git"
in_main new offline >/dev/null 2>&1
check 'new (origin unreachable, known remote branch)' origin/offline \
  "$(git -C "$WT_ROOT/owner/proj/offline" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"
git -C "$main" remote set-url origin "$origin"

in_main new >/dev/null 2>&1 && fail 'new (no branch) should fail'
(cd -- "$scratch" && "$wt_bin" new topic >/dev/null 2>&1) && fail 'new (outside a repository) should fail'

# ── pr ───────────────────────────────────────────────

got=$(STUB_PR_VIEW=$'pr-branch\tfalse' in_main pr '#7' 2>/dev/null)
check 'pr' "$WT_ROOT/owner/proj/pr-branch" "$got"
check 'pr (checked out by gh)' pr-branch \
  "$(git -C "$WT_ROOT/owner/proj/pr-branch" branch --show-current 2>/dev/null)"

STUB_PR_VIEW='' in_main pr 8 >/dev/null 2>&1 && fail 'pr (unresolved head) should fail'

check 'pr (again)' "$WT_ROOT/owner/proj/pr-branch" \
  "$(STUB_PR_VIEW=$'pr-branch\tfalse' in_main pr 7 2>/dev/null)"
# Another pull request whose head folds to the same directory.
STUB_PR_VIEW=$'pr/branch\ttrue' in_main pr 9 >/dev/null 2>&1 &&
  fail 'pr (directory holds another branch) should fail'

# ── prs ──────────────────────────────────────────────

# `<display>\t<number>`: a picker shows the first column and hands back the
# second to `wt pr`. A long title is cut so the branch and author stay visible.
long='A title long enough to run past the fifty columns kept'
got=$(STUB_PR_ROWS=$'12\tFix thing\tfix-thing\talice\n3\t'"$long"$'\tlong\tbob' in_main prs)
check 'prs' \
  "$(
    printf '#%-5s %-50s %s (@%s)\t%s\n' 12 'Fix thing' fix-thing alice 12
    printf '#%-5s %-50s %s (@%s)\t%s' 3 "${long[1,50]}" long bob 3
  )" \
  "$got"
check 'prs (none open)' '' "$(STUB_PR_ROWS='' in_main prs)"

# ── list ─────────────────────────────────────────────

check 'list' \
  'owner/proj/based
owner/proj/feat-x
owner/proj/local-only
owner/proj/offline
owner/proj/pr-branch
owner/proj/remote-only
owner/proj/topic' \
  "$(wt list)"
check 'list (query)' 'owner/proj/topic' "$(wt list topic)"
check 'list --full-path (query)' "$WT_ROOT/owner/proj/topic" "$(wt list --full-path topic)"
check 'list (empty root)' '' "$(WT_ROOT=$scratch/nowhere wt list)"

# ── rm ───────────────────────────────────────────────

# git removes the worktree the caller stands in without complaint.
check 'rm (standing in it)' 1 \
  "$(cd -- "$WT_ROOT/owner/proj/topic" && status_of "$wt_bin" rm -f "$WT_ROOT/owner/proj/topic")"
[[ -d $WT_ROOT/owner/proj/topic ]] || fail 'rm (standing in it) removed the worktree'

# Only the layout under $WT_ROOT is ours: not the main checkout, not Claude
# Code's .claude/worktrees.
check 'rm (main checkout)' 1 "$(status_of in_main rm -f "$main")"
git -C "$main" worktree add -q "$main/.claude/worktrees/agent" -b agent 2>/dev/null
check 'rm (claude worktree)' 1 "$(status_of in_main rm -f "$main/.claude/worktrees/agent")"
[[ -d $main/.claude/worktrees/agent ]] || fail 'rm (claude worktree) removed it'
check 'rm (no target)' 1 "$(status_of in_main rm)"

# A merged branch goes with its worktree; by branch name from inside the repo.
check 'rm (by branch)' "$WT_ROOT/owner/proj/topic" "$(in_main rm topic 2>/dev/null)"
[[ -d $WT_ROOT/owner/proj/topic ]] && fail 'rm (by branch) left the worktree'
git -C "$main" show-ref -q --verify refs/heads/topic && fail 'rm (merged) left the branch'

# An unmerged branch is a decision of its own: nothing is removed until the
# caller says -D (delete it) or -k (keep it). -f does not decide it.
git -C "$WT_ROOT/owner/proj/based" commit -q --allow-empty -m unmerged
check 'rm (unmerged)' 3 "$(cd -- "$scratch" && status_of "$wt_bin" rm "$WT_ROOT/owner/proj/based")"
check 'rm -f (unmerged)' 3 "$(cd -- "$scratch" && status_of "$wt_bin" rm -f "$WT_ROOT/owner/proj/based")"
[[ -d $WT_ROOT/owner/proj/based ]] || fail 'rm (unmerged) removed the worktree'
check 'rm -k (unmerged, by path, from anywhere)' "$WT_ROOT/owner/proj/based" \
  "$(cd -- "$scratch" && "$wt_bin" rm -k "$WT_ROOT/owner/proj/based" 2>/dev/null)"
git -C "$main" show-ref -q --verify refs/heads/based || fail 'rm -k deleted the branch'

in_main new unmerged main >/dev/null 2>&1
git -C "$WT_ROOT/owner/proj/unmerged" commit -q --allow-empty -m unmerged
check 'rm -D (unmerged)' "$WT_ROOT/owner/proj/unmerged" "$(in_main rm -D unmerged 2>/dev/null)"
git -C "$main" show-ref -q --verify refs/heads/unmerged && fail 'rm -D left the branch'

# Local changes are git's refusal, and -f is the caller overriding it. The
# merged branch still goes by -d.
print change >"$WT_ROOT/owner/proj/local-only/file"
check 'rm (dirty)' 2 "$(status_of in_main rm local-only)"
[[ -d $WT_ROOT/owner/proj/local-only ]] || fail 'rm (dirty) removed the worktree'
# A refusal -f cannot lift outranks one it can, so the caller does not offer it.
check 'rm (dirty and main checkout)' 1 "$(status_of in_main rm local-only "$main")"
check 'rm -f (dirty)' "$WT_ROOT/owner/proj/local-only" "$(in_main rm -f local-only 2>/dev/null)"
git -C "$main" show-ref -q --verify refs/heads/local-only && fail 'rm -f left the merged branch'

# Every target is attempted: one that cannot be resolved outside a repository
# does not stop the next.
in_main new later >/dev/null 2>&1
check 'rm (unresolvable, then a path)' 1 \
  "$(cd -- "$scratch" && status_of "$wt_bin" rm nowhere "$WT_ROOT/owner/proj/later")"
[[ -d $WT_ROOT/owner/proj/later ]] && fail 'rm stopped at an unresolvable target'

# A root reached through a symlink still names the worktrees under it.
ln -s "$WT_ROOT" "$scratch/wt-link"
in_main new linked >/dev/null 2>&1
check 'rm (by branch, symlinked root)' "$scratch/wt-link/owner/proj/linked" \
  "$(cd -- "$main" && WT_ROOT=$scratch/wt-link "$wt_bin" rm linked 2>/dev/null)"
[[ -d $WT_ROOT/owner/proj/linked ]] && fail 'rm (symlinked root) left the worktree'

# ── prune ────────────────────────────────────────────

# merged: its PR merged and origin deleted the branch. closed: origin deleted the
# branch but no PR merged. dirty: merged, but with work in the worktree. after:
# merged, then committed to locally. reused: a merged PR of the same branch name
# had another head.
export STUB_MERGED_DIR=$scratch/merged
mkdir -p "$STUB_MERGED_DIR"
for b in merged closed dirty after reused; do
  in_main new "$b" main >/dev/null 2>&1
  git -C "$WT_ROOT/owner/proj/$b" commit -q --allow-empty -m "$b"
  git -C "$WT_ROOT/owner/proj/$b" push -q -u origin "$b" 2>/dev/null
  git -C "$main" push -q origin --delete "$b" 2>/dev/null
  [[ $b == closed ]] || git -C "$main" rev-parse "refs/heads/$b" >"$STUB_MERGED_DIR/$b"
done
print change >"$WT_ROOT/owner/proj/dirty/file"
git -C "$WT_ROOT/owner/proj/after" commit -q --allow-empty -m 'after the merge'
print 0000000000000000000000000000000000000000 >"$STUB_MERGED_DIR/reused"

check 'prune --dry-run' "$WT_ROOT/owner/proj/merged" "$(in_main prune --dry-run 2>/dev/null)"
[[ -d $WT_ROOT/owner/proj/merged ]] || fail 'prune --dry-run removed a worktree'

check 'prune' "$WT_ROOT/owner/proj/merged" "$(in_main prune 2>/dev/null)"
[[ -d $WT_ROOT/owner/proj/merged ]] && fail 'prune left the merged worktree'
git -C "$main" show-ref -q --verify refs/heads/merged && fail 'prune left the merged branch'
[[ -d $WT_ROOT/owner/proj/closed ]] || fail 'prune removed an unmerged worktree'
[[ -d $WT_ROOT/owner/proj/dirty ]] || fail 'prune removed a dirty worktree'
[[ -d $WT_ROOT/owner/proj/after ]] || fail 'prune removed commits made after the merge'
[[ -d $WT_ROOT/owner/proj/reused ]] || fail 'prune removed a branch whose merged PR had another head'
# remote-only still has its upstream, so it is not a candidate at all.
[[ -d $WT_ROOT/owner/proj/remote-only ]] || fail 'prune removed a worktree whose branch is still on origin'

# ── dispatch / dependencies ──────────────────────────

wt nope >/dev/null 2>&1 && fail 'unknown subcommand should fail'
wt >/dev/null 2>&1 && fail 'no subcommand should fail'

# A PATH holding zsh and git but not gh.
nogh=$scratch/nogh
mkdir -p "$nogh"
ln -s "$(command -v zsh)" "$nogh/zsh"
ln -s "$(command -v git)" "$nogh/git"
err=$(cd -- "$main" && PATH=$nogh "$wt_bin" pr 1 2>&1 >/dev/null)
[[ $err == *'wt: gh is not installed'* ]] || fail "pr without gh: $err"
err=$(cd -- "$main" && PATH=$nogh "$wt_bin" prune 2>&1 >/dev/null)
[[ $err == *'wt: gh is not installed'* ]] || fail "prune without gh: $err"

if ((failures > 0)); then
  print -u2 "wt_test: $failures assertion(s) failed"
  exit 1
fi
print 'wt_test: ok'
