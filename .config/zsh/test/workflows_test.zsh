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

# A PATH holding only what the guards themselves need, so tv / gh / az / jq /
# herdr are guaranteed to be absent no matter what the machine has.
stub_bin=$(mktemp -d "${TMPDIR:-/tmp}/zsh-workflows-test.XXXXXX") || exit 1
scratch=$(mktemp -d "${TMPDIR:-/tmp}/zsh-workflows-repo.XXXXXX") || exit 1
trap 'rm -rf -- "$stub_bin" "$scratch"' EXIT

for cmd in git awk sed grep cut ls rm cat mktemp; do
  src=$(command -v "$cmd") || continue
  ln -s "$src" "$stub_bin/$cmd"
done
git -C "$scratch" init --quiet || exit 1

workflows_dir=${0:A:h}/../workflows

PATH=$stub_bin
hash -r
for cmd in tv gh az jq herdr; do
  command -v "$cmd" >/dev/null 2>&1 && fail "$cmd is still reachable; the stub PATH is not isolating the test"
done

# 1. Every workflow file loads on its own.
for f in "$workflows_dir"/*.zsh; do
  source "$f" || fail "${f:t}: sourcing failed"
done

# 2. Every entry point is defined even though its dependencies are missing.
for fn in wt repo dot; do
  whence -w "$fn" >/dev/null 2>&1 || fail "$fn is not defined"
done

# 3. Calling one reports the missing dependency and returns non-zero.
# <function> <expected substring in stderr>
expect_guard() {
  # `status` is a read-only alias of `?` in zsh, hence `rc`.
  local fn=$1 want=$2 err rc
  err=$("$fn" 2>&1 >/dev/null)
  rc=$?
  ((rc != 0)) || fail "$fn: expected a non-zero status"
  [[ $err == *"$want"* ]] || fail "$fn: expected stderr to contain '$want', got '$err'"
}

cd -- "$scratch" || exit 1
expect_guard wt 'wt: tv is not installed'
expect_guard repo 'repo: tv is not installed'

# 4. The repository guard fires outside a work tree instead of the tv one.
cd -- "$stub_bin" || exit 1
expect_guard wt 'wt: not inside a git repository'

# 5. Reaching this line at all is the assertion that none of the above exited
# the shell.
if ((failures > 0)); then
  print -u2 "workflows_test: $failures assertion(s) failed"
  exit 1
fi
print 'workflows_test: ok'
