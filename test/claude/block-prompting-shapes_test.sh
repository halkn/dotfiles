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
expect 2 'find . -name x -exec sed -i s/a/b/ {} +'
expect 2 'if true; then sed -i s/a/b/ x; fi'
# Address ranges.
expect 2 "sed -n '/fn a/,/^}/p' x.rs"
expect 2 "sed -n '10,/^}/p' x.rs"
expect 2 "rg -l x | xargs sed -n '/a/p'"
expect 2 "sed -n '\\#a#p' x"
# cd.
expect 2 'cd .scratch/x && rg a'
expect 2 'cd sub; ls'
expect 2 'git status && cd sub'
expect 2 "ls${nl}cd sub"
expect 2 'pushd sub'
expect 2 'CDPATH= cd sub && ls'
expect 2 '{ cd sub; ls; }'
# Temp paths outside the working directory.
expect 2 'cat "$TMPDIR/x/scratchpad/a.md"'
expect 2 'ls ${TMPDIR}/x'
expect 2 'jq . /private/tmp/claude-501/p/s/scratchpad/a.json'
expect 2 'bash x.sh > /tmp/claude-501/p/s/scratchpad/out.md'
expect 2 'ls /tmp/claude/x'
expect 2 'gh pr create --title x --body-file "$TMPDIR/x.md"'
# Arrays built inside gh --jq.
expect 2 "gh run list --json a,b --jq '.[] | [.a, .b] | @tsv'"
expect 2 "gh issue list --json labels --jq '.[] | \"\\(.number)\\t\\([.labels[].name] | join(\",\"))\"'"
expect 2 "gh pr view 1 --json a --jq='[.a]'"
expect 2 "gh pr view 1 --json a -q '{a: [.b[]]}'"
expect 2 'gh pr view 1 --json a,b --jq "[.a, .b]"'
expect 2 "gh api repos/o/r/commits --jq '\"PRs: \" + ([.[].sha] | join(\",\"))'"
# --jq on a raw response.
expect 2 "gh api -H 'Accept: application/vnd.github.raw' 'repos/o/r/contents/a.md?ref=v1' --jq ."
expect 2 "gh api -H 'Accept: application/vnd.github.raw' repos/o/r/contents/a.ts -q '.a'"

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
expect 0 "rg -n '\$TMPDIR' docs/claude-code.md"
expect 0 "perl -Mstrict -ne 'print' x"
expect 0 "perl -MList::Util=sum -ne 'print' x"
expect 0 "sed -n '1,5p' a.md${nl}rg '/api' b.md"
expect 0 'undo-cd x'
expect 0 "gh pr checks 1 --json name,bucket --jq '.[] | \"\\(.bucket)\\t\\(.name)\"'"
expect 0 "gh api repos/o/r --jq '.[\"\$defs\"].a, .jobs[0].steps[].name'"
expect 0 "gh pr view 1 --json sha --jq '.sha[0:7]'"
expect 0 "gh pr view 1 --json labels --jq '.labels | map(.name) | join(\",\")'"
expect 0 "gh api -H 'Accept: application/vnd.github.raw' 'repos/o/r/contents/a.md?ref=v1'"
expect 0 "gh pr view 1 --json title --jq .title"
expect 0 "gh api -H 'Accept: application/vnd.github.raw' 'repos/o/r/contents/s.json?ref=v1' --jq '.a'"
expect 0 "gh pr view 1 --json title,state --jq '\"\\(.title) [\\(.state)]\"'"
expect 0 "gh issue view 1 --json title,comments --jq '\"\\(.title) [\\(.comments | length) comments]\"'"
expect 0 'gh pr view 1 --json title --jq "\"[draft] \\(.title)\""'
expect 2 "gh pr view 1 --json title,labels --jq '\"[\\(.title)] \\([.labels[].name] | join(\",\"))\"'"
expect 0 "jq '[.a, .b]' x.json"
expect 0 "rg -n \"--jq '[.a]'\" docs/claude-code.md"
expect 0 'echo ok'

[ "$rc" -eq 0 ] && echo 'block-prompting-shapes_test: ok'
exit $rc
