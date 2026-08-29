#!/usr/bin/env zsh
# Tests for lib/checkout.zsh: the roots it works under, where a spec lands, and
# how a picker row reads. Everything else is git's own answer. Run with
# `mise run test:zsh`.

set -uo pipefail

source "${0:A:h}/../lib/checkout.zsh"

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

# ── clones ───────────────────────────────────────────

check '_ck_repo_root' /tmp/repos "$(REPO_ROOT=/tmp/repos _ck_repo_root)"

# A trailing slash must not double up where the callers append to the result.
check '_ck_repo_root (trailing slash)' /tmp/repos "$(REPO_ROOT=/tmp/repos/ _ck_repo_root)"

# The root is also read from a shell profile, where a leading ~ is a literal
# character rather than something the shell has already expanded.
check '_ck_repo_root (tilde)' "$HOME/repos" "$(REPO_ROOT='~/repos' _ck_repo_root)"

check '_ck_repo_root (unset)' "$HOME/repos" "$(unset REPO_ROOT && _ck_repo_root)"

dest() { REPO_ROOT=/r _ck_repo_dest "$1"; }

check '_ck_repo_dest (owner/repo)' /r/github.com/halkn/dotfiles "$(dest halkn/dotfiles)"
check '_ck_repo_dest (ssh)' /r/github.com/halkn/dotfiles "$(dest git@github.com:halkn/dotfiles.git)"
check '_ck_repo_dest (https)' /r/github.com/halkn/dotfiles "$(dest https://github.com/halkn/dotfiles)"
check '_ck_repo_dest (https, .git)' /r/github.com/halkn/dotfiles "$(dest https://github.com/halkn/dotfiles.git)"

# Azure DevOps spells the repository behind a `_git` segment, which is not part
# of the layout on disk.
check '_ck_repo_dest (azure)' /r/dev.azure.com/org/project/repo \
  "$(dest https://dev.azure.com/org/project/_git/repo)"

check '_ck_repo_dest (host shorthand)' /r/github.com/halkn/dotfiles \
  "$(dest github.com/halkn/dotfiles)"

# ── places ───────────────────────────────────────────

scratch=$(mktemp -d "${TMPDIR:-/tmp}/checkout-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT

# The listing is shared by every machine, so a path that is not on this one is
# dropped rather than offered as a row that cannot be opened. A `~` written by
# hand is expanded first, since an unexpanded one would be dropped by that same
# test with no way to tell the two apart. The tab pins the assertions to the
# target column, which is what the picker acts on.
places=$(WS_PLACES="$scratch:$scratch/absent:~" _ck_place_rows)
[[ $places == *$'\t'"${scratch:A}"$'\t'* ]] || check '_ck_place_rows' "a row for ${scratch:A}" "$places"
[[ $places != *"$scratch/absent"* ]] || check '_ck_place_rows (absent)' 'no row' "$places"
[[ $places == *$'\t'"${HOME:A}"$'\t'* ]] || check '_ck_place_rows (tilde)' "a row for ${HOME:A}" "$places"

# ── worktrees ────────────────────────────────────────

check '_ck_wt_root' /w/wt "$(WT_ROOT=/w/wt _ck_wt_root)"
check '_ck_wt_root (trailing slash)' /w/wt "$(WT_ROOT=/w/wt/ _ck_wt_root)"
check '_ck_wt_root (tilde)' "$HOME/wt" "$(WT_ROOT='~/wt' _ck_wt_root)"

# The fallback is herdr's own `[worktrees] directory`: the two place worktrees
# in one tree, so a worktree herdr created is in the listing below.
herdr_dir=$(sed -n 's/^directory = "\(.*\)"$/\1/p' "${0:A:h}/../../herdr/config.toml")
check '_ck_wt_root (unset)' "${herdr_dir/#\~/$HOME}" \
  "$(unset WT_ROOT && XDG_DATA_HOME=$HOME/.local/share _ck_wt_root)"

# A branch name becomes one path segment, so the separator has to go.
check '_ck_wt_slug' 'feature-a' "$(_ck_wt_slug 'feature/a')"
check '_ck_wt_slug (nested)' 'a-b-c' "$(_ck_wt_slug 'a/b/c')"
check '_ck_wt_slug (plain)' 'topic' "$(_ck_wt_slug topic)"

# The listing is a glob over <root>/<owner>/<repo>/<branch>, so the row is built
# from the path alone - no git call per row. Rows are
# `<display>\t<target>\t<path>`, the shape every picker consumes.
mkdir -p "$scratch/halkn/dotfiles/topic" "$scratch/halkn/other/feature-a"

check '_ck_wt_rows' \
  "$(printf 'wt   %-30s %s\t%s\t%s\n' \
    'halkn/dotfiles' 'topic' "$scratch/halkn/dotfiles/topic" "$scratch/halkn/dotfiles/topic"
  printf 'wt   %-30s %s\t%s\t%s' \
    'halkn/other' 'feature-a' "$scratch/halkn/other/feature-a" "$scratch/halkn/other/feature-a")" \
  "$(WT_ROOT=$scratch _ck_wt_rows)"

# An empty root is an empty listing rather than a glob error.
check '_ck_wt_rows (empty root)' '' "$(WT_ROOT=$scratch/nowhere _ck_wt_rows)"

# The main checkout is `git worktree list`'s first entry and is never offered
# for removal.
rows=$(
  printf 'worktree /w/repo\nHEAD abc\nbranch refs/heads/main\n\n'
  printf 'worktree /w/wt/topic\nHEAD def\nbranch refs/heads/feature/a\n\n'
  printf 'worktree /w/wt/loose\nHEAD 012\ndetached\n\n'
)
check '_ck_wt_repo_rows_filter' \
  "$(
    printf '%-40s %s\t%s\t%s\n' 'feature/a' '/w/wt/topic' '/w/wt/topic' '/w/wt/topic'
    printf '%-40s %s\t%s\t%s' '(detached)' '/w/wt/loose' '/w/wt/loose' '/w/wt/loose'
  )" \
  "$(print -r -- "$rows" | _ck_wt_repo_rows_filter /elsewhere)"

# `git worktree remove` takes the worktree you are standing in without
# complaint, leaving the shell in a directory that is gone, so it is not offered.
check '_ck_wt_repo_rows_filter (standing in one)' \
  "$(printf '%-40s %s\t%s\t%s' '(detached)' '/w/wt/loose' '/w/wt/loose' '/w/wt/loose')" \
  "$(print -r -- "$rows" | _ck_wt_repo_rows_filter /w/wt/topic)"

check '_ck_wt_repo_rows_filter (standing below one)' \
  "$(printf '%-40s %s\t%s\t%s' '(detached)' '/w/wt/loose' '/w/wt/loose' '/w/wt/loose')" \
  "$(print -r -- "$rows" | _ck_wt_repo_rows_filter /w/wt/topic/src/deep)"

# Claude Code owns the lifecycle of its own checkouts, and one of them may still
# have an agent running in it.
protected=$(
  printf 'worktree /w/repo\nHEAD abc\nbranch refs/heads/main\n\n'
  printf 'worktree /w/repo/.claude/worktrees/session\nHEAD def\nbranch refs/heads/agent\n\n'
)
check '_ck_wt_repo_rows_filter (claude worktree)' '' \
  "$(print -r -- "$protected" | _ck_wt_repo_rows_filter /elsewhere)"

if ((failures > 0)); then
  print -u2 "checkout_test: $failures assertion(s) failed"
  exit 1
fi
print 'checkout_test: ok'
