#!/usr/bin/env zsh
# Tests for the one thing `repo` still decides on its own: the root a fixed
# checkout is reached under. Turning an argument into a clone location is
# `trepo get`, and covered by trepo's own tests. Run with `mise run test:zsh`.

set -uo pipefail

source "${0:A:h}/../workflows/repo.zsh"

typeset -i failures=0

check() {
  local label=$1 want=$2 got=$3
  if [[ $got != "$want" ]]; then
    print -u2 "FAIL $label"
    print -u2 "  want: $want"
    print -u2 "  got : $got"
    ((failures++))
  fi
}

check '_repo_root' /tmp/repos "$(REPO_ROOT=/tmp/repos _repo_root)"

# A trailing slash must not double up where `dot` appends to the result.
check '_repo_root (trailing slash)' /tmp/repos "$(REPO_ROOT=/tmp/repos/ _repo_root)"

# The root is also read from a shell profile, where a leading ~ is a literal
# character rather than something the shell has already expanded.
check '_repo_root (tilde)' "$HOME/repos" "$(REPO_ROOT='~/repos' _repo_root)"

check '_repo_root (unset)' "$HOME/repos" "$(unset REPO_ROOT && _repo_root)"

if ((failures > 0)); then
  print -u2 "repo_test: $failures assertion(s) failed"
  exit 1
fi
print 'repo_test: ok'
