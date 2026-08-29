#!/usr/bin/env zsh
# Tests that workflows/ survives a machine without the optional tools: sourcing
# must succeed, every entry point must still exist, and calling one must fail
# with a message instead of killing the shell. Run with `mise run test:zsh`.

set -uo pipefail

typeset -i failures=0

fail() {
  print -u2 "FAIL $1"
  ((failures++))
}

# A PATH holding only what the guards themselves need, so fzf / gh / az / jq /
# herdr are guaranteed to be absent no matter what the machine has.
stub_bin=$(mktemp -d "${TMPDIR:-/tmp}/zsh-workflows-test.XXXXXX") || exit 1
scratch=$(mktemp -d "${TMPDIR:-/tmp}/zsh-workflows-repo.XXXXXX") || exit 1
trap 'rm -rf -- "$stub_bin" "$scratch"' EXIT

for cmd in git awk sed grep cut ls rm cat mktemp; do
  src=$(command -v "$cmd") || continue
  ln -s "$src" "$stub_bin/$cmd"
done
git -C "$scratch" init --quiet || exit 1

zsh_dir=${0:A:h}/..

PATH=$stub_bin
hash -r
for cmd in fzf gh az jq herdr; do
  command -v "$cmd" >/dev/null 2>&1 && fail "$cmd is still reachable; the stub PATH is not isolating the test"
done

# 1. Every file loads on its own. A lib file is sourced by an fzf preview
# running in a fresh shell, so it has to stand alone too.
for f in "$zsh_dir"/lib/*.zsh "$zsh_dir"/workflows/*.zsh; do
  source "$f" || fail "${f:t}: sourcing failed"
done

# 2. Every entry point is defined even though its dependencies are missing.
for fn in wk gst; do
  whence -w "$fn" >/dev/null 2>&1 || fail "$fn is not defined"
done

# The herdr popups call these by name, so a rename has to be made there too.
for fn in _wk_go_pick _wk_open_pick _wk_new; do
  whence -w "$fn" >/dev/null 2>&1 || fail "$fn is not defined"
done

# 3. Calling one reports the missing dependency and returns non-zero.
# <expected substring in stderr> <command...>
expect_guard() {
  # `status` is a read-only alias of `?` in zsh, hence `rc`.
  local want=$1 err rc
  shift
  err=$("$@" 2>&1 >/dev/null)
  rc=$?
  ((rc != 0)) || fail "$*: expected a non-zero status"
  [[ $err == *"$want"* ]] || fail "$*: expected stderr to contain '$want', got '$err'"
}

cd -- "$scratch" || exit 1
expect_guard 'wk: fzf is not installed' wk
expect_guard 'wk: fzf is not installed' wk open
expect_guard 'wk: gh is not installed' wk get
expect_guard 'wk: gh is not installed' wk pr
expect_guard 'wk: fzf is not installed' wk rm
expect_guard 'gst: fzf is not installed' gst

# An unknown subcommand is a typo, not a picker with a query.
expect_guard 'wk: unknown subcommand' wk nope

# 4. The bare form and `open` span every repository, so outside a work tree it
# is still the picker that is missing; only the subcommands acting on one
# repository need it.
cd -- "$stub_bin" || exit 1
expect_guard 'wk: fzf is not installed' wk
expect_guard 'wk: fzf is not installed' wk open
expect_guard 'wk: not inside a git repository' wk new topic
expect_guard 'wk: not inside a git repository' wk pr
expect_guard 'wk: not inside a git repository' wk rm

# 5. Reaching this line at all is the assertion that none of the above exited
# the shell.
if ((failures > 0)); then
  print -u2 "workflows_test: $failures assertion(s) failed"
  exit 1
fi
print 'workflows_test: ok'
