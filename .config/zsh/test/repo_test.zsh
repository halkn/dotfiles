#!/usr/bin/env zsh
# Tests for the pure parts of `repo`: the mapping from an argument to a checkout
# location. Run with `mise run test:zsh`.

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

# <arg> <host> <path> <url>
local -a cases=(
  'owner/repo                                  github.com   owner/repo        https://github.com/owner/repo'
  'https://github.com/owner/repo.git           github.com   owner/repo        https://github.com/owner/repo.git'
  'git@github.com:owner/repo.git               github.com   owner/repo        git@github.com:owner/repo.git'
  'ssh://git@github.com:2222/owner/repo.git    github.com   owner/repo        ssh://git@github.com:2222/owner/repo.git'
  'https://dev.azure.com/org/proj/_git/repo    dev.azure.com org/proj/repo    https://dev.azure.com/org/proj/_git/repo'
  'https://org@dev.azure.com/org/proj/_git/repo dev.azure.com org/proj/repo   https://org@dev.azure.com/org/proj/_git/repo'
  'git@ssh.dev.azure.com:v3/org/proj/repo      dev.azure.com org/proj/repo    git@ssh.dev.azure.com:v3/org/proj/repo'
)

local row arg want_host want_path want_url
local -a reply
for row in "${cases[@]}"; do
  read -r arg want_host want_path want_url <<<"$row"
  if ! _repo_parse "$arg"; then
    print -u2 "FAIL $arg: rejected"
    ((failures++))
    continue
  fi
  check "$arg (host)" "$want_host" "$reply[1]"
  check "$arg (path)" "$want_path" "$reply[2]"
  check "$arg (url)" "$want_url" "$reply[3]"
done

# Inputs with no host and no shorthand shape must be rejected rather than turned
# into a path under the root.
local bad
for bad in 'notaurl' 'owner/proj/repo' ''; do
  if _repo_parse "$bad"; then
    print -u2 "FAIL '$bad': accepted as $reply[1]/$reply[2]"
    ((failures++))
  fi
done

check '_repo_dest' /tmp/repos/github.com/owner/repo \
  "$(REPO_ROOT=/tmp/repos _repo_dest github.com owner/repo)"

# A trailing slash in REPO_ROOT must not double up in the result.
check '_repo_dest (trailing slash)' /tmp/repos/github.com/owner/repo \
  "$(REPO_ROOT=/tmp/repos/ _repo_dest github.com owner/repo)"

if ((failures > 0)); then
  print -u2 "repo_test: $failures assertion(s) failed"
  exit 1
fi
print 'repo_test: ok'
