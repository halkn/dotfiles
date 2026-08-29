#!/usr/bin/env zsh
# Tests for lib/forge.zsh: what git is handed to clone from, and the mark that
# says a repository is already cloned. The calls to gh are not tested - they are
# gh's answer, not ours. Run with `mise run test:zsh`.

set -uo pipefail

source "${0:A:h}/../lib/forge.zsh"

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

check '_forge_url (owner/repo)' https://github.com/halkn/dotfiles \
  "$(_forge_url halkn/dotfiles)"
check '_forge_url (host shorthand)' https://github.com/halkn/dotfiles \
  "$(_forge_url github.com/halkn/dotfiles)"
check '_forge_url (azure shorthand)' https://dev.azure.com/org/project/_git/repo \
  "$(_forge_url dev.azure.com/org/project/_git/repo)"

# A spec git can already read is handed over untouched, so an ssh remote stays
# ssh instead of being rewritten to https.
check '_forge_url (ssh)' git@github.com:halkn/dotfiles.git \
  "$(_forge_url git@github.com:halkn/dotfiles.git)"
check '_forge_url (https)' https://github.com/halkn/dotfiles.git \
  "$(_forge_url https://github.com/halkn/dotfiles.git)"

# The root is passed in, since where a clone lands is checkout.zsh's. A clone
# that is already there is marked rather than dropped: picking it is still a way
# to get to it.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/forge-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/github.com/halkn/dotfiles"

check '_forge_repo_rows' \
  "$(printf '✓ %s\t%s\n  %s\t%s' \
    halkn/dotfiles halkn/dotfiles halkn/absent halkn/absent)" \
  "$(_forge_repo_rows "$scratch" halkn/dotfiles halkn/absent)"

if ((failures > 0)); then
  print -u2 "forge_test: $failures assertion(s) failed"
  exit 1
fi
print 'forge_test: ok'
