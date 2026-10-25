#!/usr/bin/env zsh
# Tests for bin/hw: where a worktree lands, which branch it holds, what rm
# removes and refuses, and the rows the pickers read. It is an executable, so
# everything here runs it as a subprocess against a scratch repository. herdr,
# gh and az are stubs on PATH that log their arguments; git and jq are real.
# Run with `mise run test:scripts`.

set -uo pipefail

hw_bin=${0:A:h}/../../bin/hw

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

[[ -x $hw_bin ]] || {
  print -u2 "hw_test: $hw_bin is not executable"
  exit 1
}

# ── root ─────────────────────────────────────────────

check 'root' /w/wt "$(WT_ROOT=/w/wt "$hw_bin" root)"
check 'root (trailing slash)' /w/wt "$(WT_ROOT=/w/wt/ "$hw_bin" root)"
check 'root (tilde)' "$HOME/wt" "$(WT_ROOT='~/wt' "$hw_bin" root)"

# The fallback is herdr's own `[worktrees] directory`.
herdr_dir=$(sed -n 's/^directory = "\(.*\)"$/\1/p' "${0:A:h}/../../.config/herdr/config.toml")
check 'root (unset)' "${herdr_dir/#\~/$HOME}" \
  "$(unset WT_ROOT && XDG_DATA_HOME=$HOME/.local/share "$hw_bin" root)"

# ── fixture ──────────────────────────────────────────

scratch=$(mktemp -d "${TMPDIR:-/tmp}/hw-test.XXXXXX") || exit 1
scratch=${scratch:A}
trap 'rm -rf -- "$scratch"' EXIT

# git reads the global config through $XDG_CONFIG_HOME before $HOME, and here
# that is this repository's tracked .config/git/config.
export HOME=$scratch/home XDG_CONFIG_HOME=$scratch/home/.config
export GIT_CONFIG_GLOBAL=$scratch/home/.gitconfig GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME"
git config --global user.name hw-test
git config --global user.email hw-test@example.invalid
git config --global init.defaultBranch main

export WT_ROOT=$scratch/wt
main=$scratch/repos/github.com/owner/proj
origin=$scratch/origin.git

git init -q --bare "$origin"
git init -q "$main"
git -C "$main" commit -q --allow-empty -m init
git -C "$main" remote add origin "$origin"
git -C "$main" push -q -u origin main
git -C "$main" remote set-head origin main
git -C "$main" branch local-only
# A branch that exists only on origin, as a teammate's would.
git -C "$main" branch remote-only
git -C "$main" push -q origin remote-only
git -C "$main" branch -D -q remote-only
git -C "$main" update-ref -d refs/remotes/origin/remote-only
# hw reads the host off origin's URL; the fetches go to the bare repository.
git -C "$main" config url."$origin".insteadOf https://github.com/owner/proj.git
git -C "$main" remote set-url origin https://github.com/owner/proj.git

# The stubs: herdr answers from $STUB/ws (`<id>\t<number>\t<label>\t<path>\t
# <focused>` per workspace), $STUB/panes/<ws> (`<pane>\t<cwd>`) and
# $STUB/busy/<pane> (what the pane runs). `worktree remove` removes with git, as
# herdr does. gh and az answer from $STUB_*. Every call is logged to $STUB/log.
export STUB=$scratch/stub
mkdir -p "$STUB/bin" "$STUB/panes" "$STUB/busy"
: >"$STUB/ws"
cat >"$STUB/bin/herdr" <<'EOF'
#!/bin/zsh
print -r -- "herdr $*" >>"$STUB/log"
ws_json() {
  local row
  local -a f j
  for row in ${(f)"$(<"$STUB/ws")"}; do
    f=("${(@ps:\t:)row}")
    j+=("{\"workspace_id\":\"$f[1]\",\"number\":$f[2],\"label\":\"$f[3]\",\"focused\":$f[5]${f[4]:+,\"worktree\":{\"checkout_path\":\"$f[4]\"\}}}")
  done
  print -r -- "{\"result\":{\"workspaces\":[${(j:,:)j}]}}"
}
case "$1 $2" in
  'workspace list') ws_json ;;
  'pane list')
    j=()
    [[ -f $STUB/panes/$4 ]] && for row in ${(f)"$(<"$STUB/panes/$4")"}; do
      f=("${(@ps:\t:)row}")
      j+=("{\"pane_id\":\"$f[1]\",\"cwd\":\"$f[2]\"}")
    done
    print -r -- "{\"result\":{\"panes\":[${(j:,:)j}]}}"
    ;;
  'pane process-info')
    if [[ -f $STUB/busy/$4 ]]; then
      print -r -- "{\"result\":{\"process_info\":{\"foreground_process_group_id\":2,\"shell_pid\":1,\"foreground_processes\":[{\"cmdline\":\"$(<"$STUB/busy/$4")\"}]}}}"
    else
      print -r -- '{"result":{"process_info":{"foreground_process_group_id":1,"shell_pid":1,"foreground_processes":[{"cmdline":"-zsh"}]}}}'
    fi
    ;;
  'worktree remove')
    for row in ${(f)"$(<"$STUB/ws")"}; do
      f=("${(@ps:\t:)row}")
      [[ $f[1] == "$4" ]] || continue
      if [[ ${5-} == --force ]]; then
        git worktree remove --force -- "$f[4]" 2>/dev/null
      else
        git worktree remove -- "$f[4]" 2>/dev/null ||
          { print '{"error":{"code":"dirty_worktree_requires_force","message":"contains modified or untracked files"}}'; exit 1; }
      fi
    done
    ;;
esac
exit 0
EOF
cat >"$STUB/bin/gh" <<'EOF'
#!/bin/zsh
print -r -- "gh $*" >>"$STUB/log"
args=("$@")
case "$1 $2" in
  'pr view') print -r -- "${STUB_PR_HEAD:-}" ;;
  'pr list') print -r -- $'#3  fix it  (someone)\t3' ;;
  'pr checkout')
    at=${args[(i)--worktree]}
    git worktree add -q -b "${STUB_PR_LOCAL:-${STUB_PR_HEAD:-pr}}" -- "${args[at + 1]-}" || exit 1
    ;;
esac
EOF
cat >"$STUB/bin/az" <<'EOF'
#!/bin/zsh
print -r -- "az $*" >>"$STUB/log"
case "$2 $3" in
  'pr show') print -r -- "${STUB_AZ_SOURCE:-}" ;;
  'pr list') print -r -- $'12\tadd a thing\tSome One' ;;
esac
EOF
chmod +x "$STUB/bin/"*
export PATH=$STUB/bin:$PATH

hw() {
  (cd -- "$main" && "$hw_bin" "$@")
}
status_of() {
  "$@" >/dev/null 2>&1
  print $?
}
logged() { [[ -f $STUB/log ]] && rg -F -- "$1" "$STUB/log"; }
reset_log() { : >"$STUB/log"; }
ws() { print -r -- "$1"$'\t'"$2"$'\t'"$3"$'\t'"${4-}"$'\t'"${5:-false}" >>"$STUB/ws"; }
no_ws() {
  : >"$STUB/ws"
  rm -f -- "$STUB/panes/"*(N) "$STUB/busy/"*(N)
}

wt=$WT_ROOT/owner/proj

# ── branch ───────────────────────────────────────────

reset_log
hw branch feature/a >/dev/null 2>&1
check 'branch (fresh branch)' feature/a "$(git -C "$wt/feature-a" branch --show-current 2>/dev/null)"
logged "herdr worktree open --cwd $main --path $wt/feature-a --focus" >/dev/null ||
  fail 'branch (opens with herdr worktree open)'

hw branch local-only >/dev/null 2>&1
check 'branch (local branch)' local-only "$(git -C "$wt/local-only" branch --show-current 2>/dev/null)"

hw branch remote-only >/dev/null 2>&1
check 'branch (remote-only branch tracks origin)' origin/remote-only \
  "$(git -C "$wt/remote-only" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"

hw branch based main >/dev/null 2>&1
check 'branch (base)' "$(git -C "$main" rev-parse main)" "$(git -C "$wt/based" rev-parse HEAD 2>/dev/null)"
hw branch main main >/dev/null 2>&1 && fail 'branch (base on an existing branch) should fail'

# A fresh branch forks from the checkout the caller stands in.
git -C "$wt/based" commit -q --allow-empty -m ahead
(cd -- "$wt/based" && "$hw_bin" branch from-here >/dev/null 2>&1)
check 'branch (from a worktree)' "$(git -C "$wt/based" rev-parse HEAD)" \
  "$(git -C "$wt/from-here" rev-parse HEAD 2>/dev/null)"

# An existing worktree is opened again; herdr focuses the workspace already on it.
reset_log
hw branch feature/a >/dev/null 2>&1 || fail 'branch (existing worktree) should succeed'
logged "herdr worktree open --cwd $main --path $wt/feature-a --focus" >/dev/null ||
  fail 'branch (existing worktree is opened again)'
hw branch feature-a >/dev/null 2>&1 && fail 'branch (directory holds another branch) should fail'
hw branch >/dev/null 2>&1 && fail 'branch (no name) should fail'

# ── pr ───────────────────────────────────────────────

reset_log
STUB_PR_HEAD=pr-head hw pr '#7' >/dev/null 2>&1
check 'pr (github)' pr-head "$(git -C "$wt/pr-head" branch --show-current 2>/dev/null)"
logged 'gh pr checkout 7 --worktree' >/dev/null || fail 'pr (github) calls gh pr checkout'
logged "herdr worktree open --cwd $main --path $wt/pr-head --focus" >/dev/null || fail 'pr (github) opens it'

STUB_PR_HEAD='' hw pr 8 >/dev/null 2>&1 && fail 'pr (unresolved head) should fail'

# Azure DevOps: the source branch is fetched from origin and tracked.
git -C "$main" branch az-topic
git -C "$main" push -q origin az-topic
git -C "$main" branch -D -q az-topic
git -C "$main" update-ref -d refs/remotes/origin/az-topic
for url in https://dev.azure.com/org/proj/_git/proj git@ssh.dev.azure.com:v3/org/proj/proj \
  https://org.visualstudio.com/proj/_git/proj; do
  git -C "$main" config url."$origin".insteadOf "$url"
  git -C "$main" remote set-url origin "$url"
  reset_log
  STUB_AZ_SOURCE=refs/heads/az-topic hw pr 12 >/dev/null 2>&1
  logged 'az repos pr show --id 12' >/dev/null || fail "pr (azure, $url) calls az"
  logged 'gh ' >/dev/null && fail "pr (azure, $url) calls gh"
done
check 'pr (azure tracks origin)' origin/az-topic \
  "$(git -C "$wt/az-topic" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)"
STUB_AZ_SOURCE=refs/heads/nowhere hw pr 13 >/dev/null 2>&1 && fail 'pr (azure, branch not on origin) should fail'
[[ -e $wt/nowhere ]] && fail 'pr (azure, branch not on origin) left a worktree'
check 'prs (azure)' $'!12  add a thing  (Some One)\t12' "$(hw prs 2>/dev/null)"

git -C "$main" config url."$origin".insteadOf https://github.com/owner/proj.git
git -C "$main" remote set-url origin https://github.com/owner/proj.git
check 'prs (github)' $'#3  fix it  (someone)\t3' "$(hw prs 2>/dev/null)"

# A PATH holding zsh, git, jq and the herdr stub but neither gh nor az.
bare=$scratch/bare
mkdir -p "$bare"
for t in zsh git jq; do ln -s "$(command -v "$t")" "$bare/$t"; done
ln -s "$STUB/bin/herdr" "$bare/herdr"
err=$(cd -- "$main" && PATH=$bare "$hw_bin" pr 1 2>&1 >/dev/null)
[[ $err == *'hw: gh is not installed'* ]] || fail "pr without gh: $err"
git -C "$main" remote set-url origin https://dev.azure.com/org/proj/_git/proj
err=$(cd -- "$main" && PATH=$bare "$hw_bin" pr 1 2>&1 >/dev/null)
[[ $err == *'hw: az is not installed'* ]] || fail "pr without az: $err"
git -C "$main" remote set-url origin https://github.com/owner/proj.git

# ── branches / spaces / focused ──────────────────────

git -C "$main" branch spare
got=$(hw branches 2>/dev/null)
[[ $got == *$'worktree feature/a\tfeature/a'* ]] || fail "branches (worktree): $got"
[[ $got == *$'local    spare\tspare'* ]] || fail "branches (local): $got"
git -C "$main" branch solo
git -C "$main" push -q origin solo
git -C "$main" branch -D -q solo
[[ $(hw branches 2>/dev/null) == *$'origin   solo\tsolo'* ]] || fail 'branches (origin only)'
[[ ${${(f)got}[1]} == worktree* ]] || fail "branches (worktrees first): $got"

no_ws
ws w1 1 proj "$main" true
ws w2 2 feature-a "$wt/feature-a"
ws w3 3 dup ''
ws w4 4 again "$wt/feature-a"
ws w5 5 '~' "$HOME/else"
check 'spaces' "$(printf '%s\t%s\t%s\t%s\n' \
  '[2] owner/proj feature/a' rm "$wt/feature-a" "$wt/feature-a" \
  '[3] dup' close w3 '' \
  '[5] ~/else' close w5 "$HOME/else")" "$(hw spaces 2>/dev/null)"
check 'spaces (focused by id)' 4 "$(HERDR_ACTIVE_WORKSPACE_ID=w2 hw spaces 2>/dev/null | wc -l | tr -d ' ')"

check 'focused' "$main" "$(hw focused 2>/dev/null)"
check 'focused (by id)' "$wt/feature-a" "$(HERDR_ACTIVE_WORKSPACE_ID=w2 hw focused 2>/dev/null)"
check 'focused (off a checkout)' /x "$(HERDR_ACTIVE_WORKSPACE_ID=w3 HERDR_ACTIVE_PANE_CWD=/x hw focused 2>/dev/null)"
HERDR_ACTIVE_WORKSPACE_ID=w3 hw focused >/dev/null 2>&1 && fail 'focused (no checkout, no cwd) should fail'

# ── rm ───────────────────────────────────────────────

no_ws
# Only the layout under $WT_ROOT is ours, and never the worktree you stand in.
check 'rm (main checkout)' 1 "$(status_of hw rm -f "$main")"
git -C "$main" worktree add -q "$main/.claude/worktrees/agent" -b agent 2>/dev/null
check 'rm (claude worktree)' 1 "$(status_of hw rm -f "$main/.claude/worktrees/agent")"
check 'rm (standing in it)' 1 "$(cd -- "$wt/local-only" && status_of "$hw_bin" rm -f "$wt/local-only")"
[[ -d $wt/local-only ]] || fail 'rm (standing in it) removed the worktree'
check 'rm (no target)' 1 "$(status_of hw rm)"

# A merged branch goes with its worktree.
hw rm local-only >/dev/null 2>&1 || fail 'rm (merged) should succeed'
[[ -d $wt/local-only ]] && fail 'rm (merged) left the worktree'
git -C "$main" show-ref -q --verify refs/heads/local-only && fail 'rm (merged) left the branch'

# A squash merge: the default branch has the change, but none of its commits.
git -C "$wt/based" reset -q --hard main
print change >"$wt/based/file"
git -C "$wt/based" add file
git -C "$wt/based" commit -q -m change
git -C "$main" merge -q --squash based >/dev/null 2>&1
git -C "$main" commit -q -m 'squash based'
git -C "$main" push -q origin main 2>/dev/null
git -C "$main" fetch -q origin
hw rm based >/dev/null 2>&1 || fail 'rm (squashed) should succeed'
git -C "$main" show-ref -q --verify refs/heads/based && fail 'rm (squashed) left the branch'

# An unmerged branch stays, with a word on stderr.
print unmerged >"$wt/from-here/other"
git -C "$wt/from-here" add other
git -C "$wt/from-here" commit -q -m unmerged
err=$(hw rm from-here 2>&1 >/dev/null) || fail 'rm (unmerged) should remove the worktree'
git -C "$main" show-ref -q --verify refs/heads/from-here || fail 'rm (unmerged) deleted the branch'
[[ $err == *'kept the branch from-here'* ]] || fail "rm (unmerged) says so: $err"

# Local changes are git's refusal; -f overrides it.
hw branch dirty >/dev/null 2>&1
print dirty >"$wt/dirty/file"
hw rm dirty >/dev/null 2>&1 && fail 'rm (dirty) should fail'
[[ -d $wt/dirty ]] || fail 'rm (dirty) removed the worktree'
hw rm -f dirty >/dev/null 2>&1 || fail 'rm -f (dirty) should succeed'
[[ -d $wt/dirty ]] && fail 'rm -f (dirty) left the worktree'

# herdr removes the worktree of the workspace carrying it, and every other
# workspace standing on it is closed; a dirty one through herdr is refused too.
hw branch carried >/dev/null 2>&1
no_ws
ws w7 7 carried "$wt/carried"
ws w8 8 stray ''
print -r -- $'w8:p1\t'"$wt/carried/sub" >"$STUB/panes/w8"
print dirty >"$wt/carried/untracked"
reset_log
check 'rm (dirty, through herdr)' 1 "$(status_of hw rm carried)"
logged 'herdr workspace close' >/dev/null && fail 'rm (dirty, through herdr) closed a workspace'
rm -- "$wt/carried/untracked"
reset_log
hw rm carried >/dev/null 2>&1 || fail 'rm (through herdr) should succeed'
logged 'herdr worktree remove --workspace w7' >/dev/null || fail 'rm (through herdr) asks herdr'
logged 'herdr workspace close w8' >/dev/null || fail 'rm (through herdr) closes the stray workspace'
[[ -d $wt/carried ]] && fail 'rm (through herdr) left the worktree'

# A running process in any pane on it is a refusal that -f lifts.
hw branch busy >/dev/null 2>&1
no_ws
ws w9 9 busy "$wt/busy"
print -r -- $'w9:p1\t'"$wt/busy" >"$STUB/panes/w9"
print -r -- 'sleep 600' >"$STUB/busy/w9:p1"
err=$(hw rm busy 2>&1 >/dev/null) && fail 'rm (busy) should fail'
[[ $err == *'w9:p1 is running sleep 600'* ]] || fail "rm (busy) names the process: $err"
[[ -d $wt/busy ]] || fail 'rm (busy) removed the worktree'
reset_log
hw rm -f busy >/dev/null 2>&1 || fail 'rm -f (busy) should succeed'
logged 'herdr worktree remove --workspace w9 --force' >/dev/null || fail 'rm -f (busy) forces herdr'

# By workspace id, and every target is attempted.
hw branch by-id >/dev/null 2>&1
no_ws
ws w10 10 by-id "$wt/by-id"
check 'rm (unknown, then an id)' 1 "$(status_of hw rm nowhere w10)"
[[ -d $wt/by-id ]] && fail 'rm stopped at an unknown target'
no_ws

# The default branch stays even when its worktree goes.
git -C "$main" switch -q -c elsewhere
git -C "$main" worktree add -q "$wt/main" main
hw rm "$wt/main" >/dev/null 2>&1
git -C "$main" show-ref -q --verify refs/heads/main || fail 'rm deleted the default branch'
git -C "$main" switch -q main

# ── close / dispatch ─────────────────────────────────

reset_log
hw close w3 w5 >/dev/null 2>&1
logged 'herdr workspace close w5' >/dev/null || fail 'close'
"$hw_bin" nope >/dev/null 2>&1 && fail 'unknown subcommand should fail'
"$hw_bin" >/dev/null 2>&1 && fail 'no subcommand should fail'

if ((failures > 0)); then
  print -u2 "hw_test: $failures assertion(s) failed"
  exit 1
fi
print 'hw_test: ok'
