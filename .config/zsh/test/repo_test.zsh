#!/usr/bin/env zsh
# Tests for what `repo` decides on its own: the root it works under, and where
# an argument to `repo get` lands. Run with `mise run test:zsh`.

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

# A trailing slash must not double up where the callers append to the result.
check '_repo_root (trailing slash)' /tmp/repos "$(REPO_ROOT=/tmp/repos/ _repo_root)"

# The root is also read from a shell profile, where a leading ~ is a literal
# character rather than something the shell has already expanded.
check '_repo_root (tilde)' "$HOME/repos" "$(REPO_ROOT='~/repos' _repo_root)"

check '_repo_root (unset)' "$HOME/repos" "$(unset REPO_ROOT && _repo_root)"

dest() { REPO_ROOT=/r _repo_dest "$1"; }

check '_repo_dest (owner/repo)' /r/github.com/halkn/dotfiles "$(dest halkn/dotfiles)"
check '_repo_dest (ssh)' /r/github.com/halkn/dotfiles "$(dest git@github.com:halkn/dotfiles.git)"
check '_repo_dest (https)' /r/github.com/halkn/dotfiles "$(dest https://github.com/halkn/dotfiles)"
check '_repo_dest (https, .git)' /r/github.com/halkn/dotfiles "$(dest https://github.com/halkn/dotfiles.git)"

# Azure DevOps spells the repository behind a `_git` segment, which is not part
# of the layout on disk.
check '_repo_dest (azure)' /r/dev.azure.com/org/project/repo \
  "$(dest https://dev.azure.com/org/project/_git/repo)"

if ((failures > 0)); then
  print -u2 "repo_test: $failures assertion(s) failed"
  exit 1
fi
print 'repo_test: ok'
