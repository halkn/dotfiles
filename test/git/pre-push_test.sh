#!/usr/bin/env bash
# Tests for .config/git/hooks/pre-push, run by `git push --dry-run` against a scratch bare
# remote. Run with `mise run test:scripts`.
set -uo pipefail

hook_dir="$(CDPATH= cd -- "$(dirname -- "$0")/../../.config/git/hooks" && pwd)"
rc=0

fail() {
  printf 'FAIL %s: want %s, got %s: %.80s\n' "$1" "$2" "$3" "$4" >&2
  rc=1
}

# macOS mktemp ignores $TMPDIR without a template; an empty $pp would point git at this repo.
pp="$(mktemp -d "${TMPDIR:-/tmp}/test-pre-push.XXXXXX")" || exit 1
trap 'rm -rf "$pp"' EXIT

g() {
  git -C "$pp/w" -c core.hooksPath="$hook_dir" -c user.name=t -c user.email=t@t "$@"
}

# pre_push <agent|human>[-allow] <push args>: the -allow form sets ALLOW_FORCE_PUSH=1.
pre_push() {
  local who="$1"
  shift
  (
    unset CLAUDE_CODE_CHILD_SESSION ALLOW_FORCE_PUSH
    case "$who" in
      agent*)
        export CLAUDE_CODE_CHILD_SESSION=1
        ;;
    esac
    case "$who" in
      *-allow)
        export ALLOW_FORCE_PUSH=1
        ;;
    esac
    g push --dry-run -q "$@"
  ) 2>&1 >/dev/null
}

# expect_pre_push <who> <ok|reject> <push args>: a refusal counts only with the hook's own
# message, so a crash in the hook (also a non-zero exit) does not pass as one.
expect_pre_push() {
  local who="$1" want="$2" got=ok err
  shift 2
  if ! err="$(pre_push "$who" "$@")"; then
    got="crash: $err"
    grep -q '^pre-push: ' <<<"$err" && got=reject
  fi
  [ "$got" = "$want" ] || fail pre-push "$want" "$got" "$who: git push $*"
}

git init -q --bare "$pp/r.git" || exit 1
git init -q -b main "$pp/w" || exit 1
g remote add origin "$pp/r.git"
g commit -q --allow-empty -m c1
g tag v1
g switch -q -c feat && g commit -q --allow-empty -m c2
g switch -q -c div main && g commit -q --allow-empty -m c4
g switch -q -c trunk main
(unset CLAUDE_CODE_CHILD_SESSION && g push -q origin main feat div trunk v1) >/dev/null 2>&1 || exit 1
g symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/trunk
g switch -q feat && g commit -q --allow-empty -m c3
g switch -q div && g reset -q --hard main && g commit -q --allow-empty -m c5
g tag -f v1 feat >/dev/null
g tag v2 feat
orphan="$(g commit-tree "$(g write-tree)" -m orphan)" || exit 1

expect_pre_push agent ok origin feat
expect_pre_push agent ok origin feat:refs/heads/new-branch
expect_pre_push agent ok origin v2
expect_pre_push agent reject origin +div
expect_pre_push agent reject -uf origin div
expect_pre_push agent reject origin :feat
expect_pre_push agent reject --delete origin feat
expect_pre_push agent reject --del origin feat
expect_pre_push agent reject origin feat:main
expect_pre_push agent reject origin feat:develop
expect_pre_push agent reject origin feat:release/1.0
expect_pre_push agent reject origin feat:trunk
expect_pre_push agent reject origin +v1
expect_pre_push agent-allow reject origin +div

expect_pre_push human ok origin +div
expect_pre_push human ok origin +v1
expect_pre_push human ok origin feat:main
expect_pre_push human ok origin feat:develop
expect_pre_push human reject origin "+$orphan:main"
expect_pre_push human reject origin :main
expect_pre_push human-allow ok origin "+$orphan:main"
expect_pre_push human-allow ok origin :main

[ "$rc" -eq 0 ] && echo 'pre-push_test: ok'
exit $rc
