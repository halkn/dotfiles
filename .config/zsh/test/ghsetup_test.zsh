#!/usr/bin/env zsh
# Tests for the ruleset ghsetup writes: it has to be JSON gh can post, and the
# three properties that make it a guard rather than a formality - no bypass
# actor, active enforcement, and the rules that block a direct push - have to
# survive edits to the payload. The calls to gh are not tested; they are gh's
# answer, not ours. Run with `mise run test:zsh`.

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

if ! command -v jq >/dev/null 2>&1; then
  print -u2 'ghsetup_test: jq is not installed; run `mise install`'
  exit 1
fi

payload=$(_forge_ruleset_payload)

if ! print -r -- "$payload" | jq -e . >/dev/null 2>&1; then
  print -u2 'FAIL _forge_ruleset_payload is not valid JSON'
  ((failures++))
fi

jq_get() {
  print -r -- "$payload" | jq -r "$1"
}

check 'ruleset targets the default branch' '~DEFAULT_BRANCH' \
  "$(jq_get '.conditions.ref_name.include | join(",")')"
check 'ruleset is enforced' active "$(jq_get '.enforcement')"

# An admin bypass would also be a bypass for anything running under the same
# token, which is the case this ruleset exists for.
check 'ruleset grants no bypass' 0 "$(jq_get '.bypass_actors | length')"

check 'ruleset blocks deletion, force push and direct push' \
  'deletion,non_fast_forward,pull_request' \
  "$(jq_get '.rules | map(.type) | sort | join(",")')"

# A lone owner cannot approve their own pull request, so any count above zero
# would lock the repository rather than guard it.
check 'pull request rule asks for no approval' 0 \
  "$(jq_get '.rules[] | select(.type == "pull_request") | .parameters.required_approving_review_count')"

# The repositories here carry merge commits, so restricting the methods would
# break the current flow.
check 'pull request rule allows every merge method' 'merge,rebase,squash' \
  "$(jq_get '.rules[] | select(.type == "pull_request") | .parameters.allowed_merge_methods | sort | join(",")')"

if ((failures > 0)); then
  print -u2 "ghsetup_test: $failures assertion(s) failed"
  exit 1
fi
print 'ghsetup_test: ok'
