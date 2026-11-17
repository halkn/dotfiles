#!/usr/bin/env bash
# Tests for claude/hooks/block-prompting-shapes.sh: the exit code it returns for a Bash tool call.
# Run with `mise run test:scripts`.
set -uo pipefail

hooks="$(CDPATH= cd -- "$(dirname -- "$0")/../../claude/hooks" && pwd)"
rc=0
nl=$'\n'

# expect <exit code> <command>
expect() {
  local got
  jq -n --arg c "$2" '{cwd: "/repo", tool_input: {command: $c}}' \
    | bash "$hooks/block-prompting-shapes.sh" >/dev/null 2>&1
  got=$?
  if [ "$got" -ne "$1" ]; then
    printf 'FAIL block-prompting-shapes.sh: want %s, got %s: %.80s\n' "$1" "$got" "$2" >&2
    rc=1
  fi
}

# In-place edits.
expect 2 "sed -i '' 's/a/b/' x.md"
expect 2 "sed -i 's/a/b/' x.md"
expect 2 "sed -Ei 's/a/b/' x.md"
expect 2 "sed -E -i '' 's/a/b/' x.md"
expect 2 "sed --in-place 's/a/b/' x.md"
expect 2 "git diff && sed -i '' -e '1s/a/b/' x.md"
expect 2 "perl -pi -e 's/a/b/' x.md"
expect 2 "perl -i.bak -pe 's/a/b/' x.md"
# Address ranges.
expect 2 "sed -n '/fn a/,/^}/p' x.rs"
expect 2 "sed -n '10,/^}/p' x.rs"
expect 2 "rg -l x | xargs sed -n '/a/p'"
# cd.
expect 2 'cd .scratch/x && rg a'
expect 2 'cd sub; ls'
expect 2 'git status && cd sub'
expect 2 "ls${nl}cd sub"
expect 2 'pushd sub'
# Temp paths outside the working directory.
expect 2 'cat "$TMPDIR/x/scratchpad/a.md"'
expect 2 'ls ${TMPDIR}/x'
expect 2 'jq . /private/tmp/claude-501/p/s/scratchpad/a.json'
expect 2 'bash x.sh > /tmp/claude-501/p/s/scratchpad/out.md'

expect 0 "sed -n '1,40p' x.md"
expect 0 "sed 's/a/b/' x.md"
expect 0 "rg -n 'sed -i' README.md"
expect 0 "rg -n 'a/,/b' README.md"
expect 0 "git log --format='%s' -- sed-i"
expect 0 'git diff --stat'
expect 0 "rg 'cd x' README.md"
expect 0 'mise run lint'
expect 0 'abcd x'
expect 0 'git commit -m "cd into it"'
expect 0 'gh pr create --title x --body-file /private/tmp/claude-501/p/s/scratchpad/pr.md'
expect 0 'gh issue comment 1 -F /tmp/claude-501/p/s/scratchpad/c.md'
expect 0 "rg -n 'TMPDIR' docs/claude-code.md"
expect 0 'echo ok'

[ "$rc" -eq 0 ] && echo 'block-prompting-shapes_test: ok'
exit $rc
