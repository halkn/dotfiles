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

workflows_dir=${0:A:h}/../workflows

PATH=$stub_bin
hash -r
for cmd in fzf gh az jq herdr; do
  command -v "$cmd" >/dev/null 2>&1 && fail "$cmd is still reachable; the stub PATH is not isolating the test"
done

# 1. Every workflow file loads on its own.
for f in "$workflows_dir"/*.zsh; do
  source "$f" || fail "${f:t}: sourcing failed"
done

# 2. Every entry point is defined even though its dependencies are missing.
for fn in wt repo gst ws; do
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
expect_guard 'wt: fzf is not installed' wt
expect_guard 'wt: gh is not installed' wt pr
expect_guard 'repo: fzf is not installed' repo
expect_guard 'gst: fzf is not installed' gst
expect_guard 'ws: fzf is not installed' ws

# The places listing is shared by every machine, so a path that is not on this
# one is dropped rather than offered as a row that cannot be opened. A `~`
# written by hand is expanded first, since an unexpanded one would be dropped by
# that same test with no way to tell the two apart. The tab pins the assertions
# to the path column, which is what the picker acts on.
export WS_PLACES="$scratch:$scratch/absent:~"
places=$(_ws_place_rows)
[[ $places == *$'\t'"${scratch:A}"* ]] || fail "_ws_place_rows: expected ${scratch:A} in the listing"
[[ $places != *"$scratch/absent"* ]] || fail '_ws_place_rows: listed a directory that does not exist'
[[ $places == *$'\t'"${HOME:A}"* ]] || fail '_ws_place_rows: dropped a ~ entry instead of expanding it'

# ws lists the repositories through repo.zsh, which workflow files do not source
# for each other. The herdr popup loads both, but a caller that loads
# workspace.zsh alone has to get the places rather than an error.
rows=$(
  unset -f _repo_rows
  _ws_rows
) || fail '_ws_rows: failed without repo.zsh'
[[ $rows == *$'\t'"${scratch:A}"* ]] || fail '_ws_rows: dropped the places when repo.zsh was absent'

# 4. `wt` spans every repository, so outside a work tree it is still the picker
# that is missing; only the subcommands need a repository to act on.
cd -- "$stub_bin" || exit 1
expect_guard 'wt: fzf is not installed' wt
expect_guard 'wt: not inside a git repository' wt new topic
expect_guard 'wt: not inside a git repository' wt pr
expect_guard 'wt: not inside a git repository' wt rm

# 5. Reaching this line at all is the assertion that none of the above exited
# the shell.
if ((failures > 0)); then
  print -u2 "workflows_test: $failures assertion(s) failed"
  exit 1
fi
print 'workflows_test: ok'
