#!/usr/bin/env zsh
# Tests for the pure part of `wt`: laying the trepo answer out as picker rows.
# Everything else the file does - deciding which checkouts exist, what state
# each is in and whether one may be removed - is trepo's, and is covered by
# trepo's own tests. Run with `mise run test:zsh`.

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

# As `trepo list --worktrees --here` returns it (trepo v0.5.0): four tab
# separated fields, with the first two padded out to 28 columns.
rows=$(
  printf '%-28s\t%-28s\t%s\t%s\n' 'halkn/repo1' 'topic1' 'no-upstream' '/w/wt/topic1'
  printf '%-28s\t%-28s\t%s\t%s\n' 'halkn/repo1' 'feature/a-branch-name-past-trepos-own-width' 'dirty,merged' '/w/wt/long'
  printf '%-28s\t%-28s\t%s\t%s\n' 'halkn/repo1' '-' 'detached' '/w/wt/loose'
)

# The display column is one field and the path is the next, so fzf can show the
# first and hand back the second. The slug is dropped: --here makes it the same
# on every row.
check 'a padded row becomes a display column and a path' \
  "$(printf '%-34s %-26s\t%s' 'topic1' 'no-upstream' '/w/wt/topic1')" \
  "$(print -r -- "$rows" | _wt_format_rows | sed -n 1p)"

# trepo pads to 28 and this picker lays out to 34, so a branch longer than
# trepo's width would push the flags out of line if the padding were kept.
# Taking it off again is what keeps the columns straight at any branch length.
check 'a branch past trepos width does not shift the flags' \
  "$(printf '%-34s %-26s\t%s' 'feature/a-branch-name-past-trepos-own-width' 'dirty,merged' '/w/wt/long')" \
  "$(print -r -- "$rows" | _wt_format_rows | sed -n 2p)"

# A detached checkout has no branch, and trepo says so with a dash rather than
# an empty field, which is what keeps the column count the same on every row.
check 'a detached checkout keeps its columns' \
  "$(printf '%-34s %-26s\t%s' '-' 'detached' '/w/wt/loose')" \
  "$(print -r -- "$rows" | _wt_format_rows | sed -n 3p)"

check 'no worktrees is no rows' '' "$(printf '' | _wt_format_rows)"

if ((failures > 0)); then
  print -u2 "worktree_test: $failures assertion(s) failed"
  exit 1
fi
print 'worktree_test: ok'
