#!/usr/bin/env zsh
# Tests for bin/repo: the listing it serves, where a spec lands, and the ruleset
# it writes. It is an executable rather than a sourced function, so everything
# here runs it as a subprocess and reads stdout - which is the whole interface.
# The calls to gh are not tested; they are gh's answer, not ours. Run with
# `mise run test:zsh`.

set -uo pipefail

repo_bin=${0:A:h}/../../../bin/repo

typeset -i failures=0

fail_arg() {
  print -u2 "FAIL $1"
  ((failures++))
}

check() {
  local label=$1 want=$2 got=$3
  if [[ $got != "$want" ]]; then
    print -u2 "FAIL $label"
    print -u2 "  want: ${want//$'\n'/ | }"
    print -u2 "  got : ${got//$'\n'/ | }"
    ((failures++))
  fi
}

[[ -x $repo_bin ]] || {
  print -u2 "repo_test: $repo_bin is not executable"
  exit 1
}

repo() { "$repo_bin" "$@"; }

# ── root ─────────────────────────────────────────────

check 'root' /tmp/repos "$(REPO_ROOT=/tmp/repos repo root)"

# A trailing slash must not double up where the callers append to the result.
check 'root (trailing slash)' /tmp/repos "$(REPO_ROOT=/tmp/repos/ repo root)"

# A leading ~ read from a shell profile is a literal character.
check 'root (tilde)' "$HOME/repos" "$(REPO_ROOT='~/repos' repo root)"

check 'root (unset)' "$HOME/repos" "$(unset REPO_ROOT && repo root)"

# ── list ─────────────────────────────────────────────

scratch=$(mktemp -d "${TMPDIR:-/tmp}/repo-test.XXXXXX") || exit 1
trap 'rm -rf -- "$scratch"' EXIT

# A clone is recognised by the .git it carries. The second depth is the
# <host>/<org>/<project>/<repo> Azure DevOps needs.
mkdir -p "$scratch/github.com/halkn/dotfiles/.git" \
  "$scratch/github.com/halkn/git-fz/.git" \
  "$scratch/dev.azure.com/org/project/repo/.git" \
  "$scratch/github.com/halkn/not-a-clone"

list() { REPO_ROOT=$scratch repo list "$@"; }

check 'list' \
  'dev.azure.com/org/project/repo
github.com/halkn/dotfiles
github.com/halkn/git-fz' \
  "$(list)"

check 'list --full-path' \
  "$scratch/dev.azure.com/org/project/repo
$scratch/github.com/halkn/dotfiles
$scratch/github.com/halkn/git-fz" \
  "$(list --full-path)"

# The query is a substring of the path as listed, which is how ghq reads it.
check 'list (query)' 'github.com/halkn/dotfiles' "$(list dotfiles)"
check 'list (query, owner)' \
  'github.com/halkn/dotfiles
github.com/halkn/git-fz' \
  "$(list halkn)"
check 'list (query, no match)' '' "$(list nothing-here)"

# An empty root is an empty listing rather than a glob error.
check 'list (empty root)' '' "$(REPO_ROOT=$scratch/nowhere repo list)"

# ── dest ─────────────────────────────────────────────

# Where a spec lands is what `get` would clone into, so it answers without
# touching the network.
dest() { REPO_ROOT=/r repo dest "$1"; }

check 'dest (owner/repo)' /r/github.com/halkn/dotfiles "$(dest halkn/dotfiles)"
check 'dest (ssh)' /r/github.com/halkn/dotfiles "$(dest git@github.com:halkn/dotfiles.git)"
check 'dest (https)' /r/github.com/halkn/dotfiles "$(dest https://github.com/halkn/dotfiles)"
check 'dest (https, .git)' /r/github.com/halkn/dotfiles "$(dest https://github.com/halkn/dotfiles.git)"

# Azure DevOps spells the repository behind a `_git` segment, which is not part
# of the layout on disk.
check 'dest (azure)' /r/dev.azure.com/org/project/repo \
  "$(dest https://dev.azure.com/org/project/_git/repo)"

check 'dest (host shorthand)' /r/github.com/halkn/dotfiles \
  "$(dest github.com/halkn/dotfiles)"

# A trailing slash must not make a two-segment spec look like three, which would
# drop the host segment and land the clone off the layout.
check 'dest (trailing slash)' /r/github.com/halkn/dotfiles "$(dest halkn/dotfiles/)"
check 'dest (url, trailing slash)' /r/github.com/halkn/dotfiles \
  "$(dest https://github.com/halkn/dotfiles/)"

# ── url ──────────────────────────────────────────────

url() { repo url "$1"; }

check 'url (owner/repo)' https://github.com/halkn/dotfiles "$(url halkn/dotfiles)"
check 'url (host shorthand)' https://github.com/halkn/dotfiles \
  "$(url github.com/halkn/dotfiles)"
check 'url (azure shorthand)' https://dev.azure.com/org/project/_git/repo \
  "$(url dev.azure.com/org/project/_git/repo)"

# A spec git can already read is handed over untouched, so an ssh remote stays
# ssh instead of being rewritten to https.
check 'url (ssh)' git@github.com:halkn/dotfiles.git \
  "$(url git@github.com:halkn/dotfiles.git)"
check 'url (https)' https://github.com/halkn/dotfiles.git \
  "$(url https://github.com/halkn/dotfiles.git)"

# ── get and url, against stub git and gh ─────────────

# git and gh are replaced rather than reached for: what is asserted is which
# calls `get` makes and what it lets through to stdout, not their answers.
tools=$scratch/tools
mkdir -p "$tools"
ln -sf "$(command -v zsh)" "$tools/zsh"
ln -sf "$(command -v mkdir)" "$tools/mkdir"

cat >"$tools/git" <<'STUB'
#!/usr/bin/env zsh
print -r -- "git $*" >>"$STUB_LOG"
case "$*" in
  *clone*) mkdir -p "${@[-1]}/.git" ;;
  # The real `git pull` writes its summary to stdout, which is where the path
  # `get` prints has to be the only thing.
  *pull*) print -r -- 'Already up to date.' ;;
esac
STUB
cat >"$tools/gh" <<'STUB'
#!/usr/bin/env zsh
print -r -- "gh $*" >>"$STUB_LOG"
case "$*" in
  'api user --jq .login') print -r -- halkn ;;
esac
STUB
chmod +x "$tools/git" "$tools/gh"

stub_root=$scratch/stub-root
run_stubbed() {
  : >"$scratch/log"
  PATH=$tools STUB_LOG=$scratch/log REPO_ROOT=$stub_root "$repo_bin" "$@"
}

# An existing clone is not re-cloned, and the path is the only thing on stdout.
mkdir -p "$stub_root/github.com/halkn/present/.git"
check 'get (already cloned)' "$stub_root/github.com/halkn/present" \
  "$(run_stubbed get halkn/present)"

# `pull --ff-only` prints its summary to stdout, so the caller of
# `cd "$(repo get -u ...)"` gets a path plus chatter unless it is redirected.
check 'get -u (stdout is only the path)' "$stub_root/github.com/halkn/present" \
  "$(run_stubbed get -u halkn/present 2>/dev/null)"
[[ $(<"$scratch/log") == *'pull --ff-only'* ]] ||
  fail_arg 'get -u: expected a pull'

# A directory that is not a clone is not one: an interrupted clone or a
# hand-made directory must not be handed back as if it had been fetched.
mkdir -p "$stub_root/github.com/halkn/bogus"
run_stubbed get halkn/bogus >/dev/null 2>&1
[[ $(<"$scratch/log") == *clone* ]] ||
  fail_arg 'get (dir without .git): expected a clone'

# A bare name resolves the same way in every subcommand that takes a spec.
check 'url (bare name)' https://github.com/halkn/a-name "$(run_stubbed url a-name)"
check 'dest (bare name)' "$stub_root/github.com/halkn/a-name" \
  "$(run_stubbed dest a-name)"

# ── ruleset ──────────────────────────────────────────

# The three properties that make the ruleset a guard rather than a formality -
# no bypass actor, active enforcement, and the rules that block a direct push -
# have to survive edits to the payload.
if ! command -v jq >/dev/null 2>&1; then
  print -u2 'repo_test: jq is not installed; run `mise install`'
  exit 1
fi

payload=$(repo setup --print-ruleset)

if ! print -r -- "$payload" | jq -e . >/dev/null 2>&1; then
  print -u2 'FAIL setup --print-ruleset is not valid JSON'
  ((failures++))
fi

jq_get() {
  print -r -- "$payload" | jq -r "$1"
}

check 'ruleset targets the default branch' '~DEFAULT_BRANCH' \
  "$(jq_get '.conditions.ref_name.include | join(",")')"

# The ruleset to update is found by name. If the payload stops carrying the name
# the lookup filters on, the next run creates a second, overlapping ruleset
# instead of updating the one that is there.
check 'ruleset carries the name the lookup filters on' main "$(jq_get '.name')"

check 'ruleset is enforced' active "$(jq_get '.enforcement')"

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

# ── arguments ────────────────────────────────────────

# <expected substring in stderr> <args...>
expect_fail() {
  local want=$1 err rc
  shift
  err=$(repo "$@" 2>&1 >/dev/null)
  rc=$?
  ((rc != 0)) || fail_arg "repo $*: expected a non-zero status"
  [[ $err == *"$want"* ]] || fail_arg "repo $*: expected stderr to contain '$want', got '$err'"
}

expect_fail 'repo: unknown subcommand' nope
expect_fail 'repo setup: unknown option' setup --nope
expect_fail 'repo setup: expected at most one repository' setup halkn/one halkn/two
expect_fail 'repo get: unknown option' get --nope halkn/dotfiles
expect_fail 'usage: repo get' get
expect_fail 'usage: repo create' create

# A repository this account cannot name is not a spec to resolve. Checked before
# gh is reached for, so it is reported as the typo it is on a machine with no gh.
expect_fail 'repo setup: expected <owner>/<repo>' setup nwo-without-a-slash

# ── missing dependencies ─────────────────────────────

# Only a bare name needs gh to resolve, and a machine without it has to be told
# so rather than left with a clone attempt that cannot work. A PATH holding
# nothing but zsh, since the shebang is resolved through it too.
stub_bin=$scratch/stub-bin
mkdir -p "$stub_bin"
ln -sf "$(command -v zsh)" "$stub_bin/zsh"

expect_missing_gh() {
  local err rc
  err=$(PATH=$stub_bin "$repo_bin" "$@" 2>&1 >/dev/null)
  rc=$?
  ((rc != 0)) || fail_arg "repo $*: expected a non-zero status"
  [[ $err == *'gh is not installed'* ]] || fail_arg "repo $*: expected a missing-gh message, got '$err'"
}

expect_missing_gh get a-bare-name
expect_missing_gh create a-bare-name
expect_missing_gh setup halkn/dotfiles

if ((failures > 0)); then
  print -u2 "repo_test: $failures assertion(s) failed"
  exit 1
fi
print 'repo_test: ok'
