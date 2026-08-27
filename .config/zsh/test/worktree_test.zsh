#!/usr/bin/env zsh
# Tests for the parts of `wt` that decide where a checkout goes and how a
# picker row reads. Everything else is git's own answer. Run with
# `mise run test:zsh`.

set -uo pipefail

source "${0:A:h}/../workflows/worktree.zsh"

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

check '_wt_root' /w/wt "$(WT_ROOT=/w/wt _wt_root)"
check '_wt_root (trailing slash)' /w/wt "$(WT_ROOT=/w/wt/ _wt_root)"
check '_wt_root (unset)' "${XDG_DATA_HOME:-$HOME/.local/share}/worktrees" \
  "$(unset WT_ROOT && _wt_root)"

# A branch name becomes one path segment, so the separator has to go.
check '_wt_slug' 'feature-a' "$(_wt_slug 'feature/a')"
check '_wt_slug (nested)' 'a-b-c' "$(_wt_slug 'a/b/c')"
check '_wt_slug (plain)' 'topic' "$(_wt_slug topic)"

# The listing is a glob over <root>/<owner>/<repo>/<branch>, so the row is built
# from the path alone - no git call per row.
scratch=$(mktemp -d "${TMPDIR:-/tmp}/wt-rows.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT
mkdir -p "$scratch/halkn/dotfiles/topic" "$scratch/halkn/other/feature-a"

check '_wt_checkout_rows' \
  "$(printf 'wt   %-30s %s\tworktree:%s\t%s\n' \
    'halkn/dotfiles' 'topic' "$scratch/halkn/dotfiles/topic" "$scratch/halkn/dotfiles/topic"
  printf 'wt   %-30s %s\tworktree:%s\t%s' \
    'halkn/other' 'feature-a' "$scratch/halkn/other/feature-a" "$scratch/halkn/other/feature-a")" \
  "$(WT_ROOT=$scratch _wt_checkout_rows)"

# An empty root is an empty listing rather than a glob error.
check '_wt_checkout_rows (empty root)' '' "$(WT_ROOT=$scratch/nowhere _wt_checkout_rows)"

# The main checkout is `git worktree list`'s first entry and is never offered
# for removal.
rows=$(
  printf 'worktree /w/repo\nHEAD abc\nbranch refs/heads/main\n\n'
  printf 'worktree /w/wt/topic\nHEAD def\nbranch refs/heads/feature/a\n\n'
  printf 'worktree /w/wt/loose\nHEAD 012\ndetached\n\n'
)
check '_wt_repo_rows_filter' \
  "$(
    printf '%-40s %s\t%s\n' 'feature/a' '/w/wt/topic' '/w/wt/topic'
    printf '%-40s %s\t%s' '(detached)' '/w/wt/loose' '/w/wt/loose'
  )" \
  "$(print -r -- "$rows" | _wt_repo_rows_filter /elsewhere)"

# `git worktree remove` takes the worktree you are standing in without
# complaint, leaving the shell in a directory that is gone, so it is not offered.
check '_wt_repo_rows_filter (standing in one)' \
  "$(printf '%-40s %s\t%s' '(detached)' '/w/wt/loose' '/w/wt/loose')" \
  "$(print -r -- "$rows" | _wt_repo_rows_filter /w/wt/topic)"

check '_wt_repo_rows_filter (standing below one)' \
  "$(printf '%-40s %s\t%s' '(detached)' '/w/wt/loose' '/w/wt/loose')" \
  "$(print -r -- "$rows" | _wt_repo_rows_filter /w/wt/topic/src/deep)"

# Claude Code owns the lifecycle of its own checkouts, and one of them may still
# have an agent running in it.
protected=$(
  printf 'worktree /w/repo\nHEAD abc\nbranch refs/heads/main\n\n'
  printf 'worktree /w/repo/.claude/worktrees/session\nHEAD def\nbranch refs/heads/agent\n\n'
)
check '_wt_repo_rows_filter (claude worktree)' '' \
  "$(print -r -- "$protected" | _wt_repo_rows_filter /elsewhere)"

if ((failures > 0)); then
  print -u2 "worktree_test: $failures assertion(s) failed"
  exit 1
fi
print 'worktree_test: ok'
