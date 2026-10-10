#!/usr/bin/env bash
# Tests for claude/hooks/block-piped-excluded.sh: the exit code it returns for a Bash tool call.
# Run with `mise run test:scripts`.
set -uo pipefail

hooks="$(cd "$(dirname "$0")/../../claude/hooks" && pwd)"
cwd=/repo
rc=0

# run <hook> <command>: prints the hook's stdout, returns its exit code.
run() {
  jq -n --arg c "$2" --arg d "$cwd" '{cwd: $d, tool_input: {command: $c}}' | bash "$hooks/$1" 2>/dev/null
}

fail() {
  printf 'FAIL %s: want %s, got %s: %.80s\n' "$1" "$2" "$3" "$4"
  rc=1
}

nl=$'\n'

# expect <exit code> <command>
expect() {
  local got
  run block-piped-excluded.sh "$2" >/dev/null
  got=$?
  [ "$got" -eq "$1" ] || fail block-piped-excluded.sh "$1" "$got" "$2"
}

expect 2 'git ls-remote origin HEAD | head -1'
expect 2 'true && git push'
expect 2 'git push && true'
expect 2 'git push; true'
expect 2 'cd /x; git push'
expect 2 "git push${nl}true"
expect 2 'gh pr view $(git branch --show-current)'
expect 2 'gh api x -H "a: $(echo a)"'
expect 2 'gh api x -H "a: `echo a`"'
expect 2 'git push |& tail'
expect 2 'git push || true'
expect 2 'diff <(gh api x) y'
expect 2 'cd /x && git push | tail'
expect 2 'git  push | tail'
expect 2 'cd ~/x && git push'
expect 2 'cd "/x" && git push'
expect 2 "cd '/x' && git push"
expect 2 'cd $HOME/x && git push'
expect 2 'cd "$HOME/x" && git push'
expect 2 'cd . && git push'
expect 2 'cd x && gh pr view'
expect 2 'cd /x && git push'
expect 2 'cd /x/y-z.1 && gh pr view'
expect 2 'cd /repo/sub && gh pr view'
expect 2 'git push > push.log'
expect 2 'git push >> push.log'
expect 2 'git push 2>/dev/null'
expect 2 'git push &> push.log'
expect 2 'gh api x --input - < body.json'
expect 2 "gh pr create --body-file - <<'EOF'${nl}body${nl}EOF"
expect 2 'git -C /x push'
expect 2 'git -c push.default=current push'
expect 2 'git --no-pager fetch'
expect 2 'GH_PAGER=cat gh pr view'
expect 2 "A='x y' B=1 git push"
expect 2 'env GH_PAGER=cat gh pr view'
expect 2 'env -u FOO git push'
expect 2 'nice env -u CLAUDE_CODE_CHILD_SESSION git push origin x'
expect 2 'nice -n 5 git push'
expect 2 'time gh pr view'
expect 2 'timeout 30 git fetch'
expect 2 'nohup git push'
expect 2 'stdbuf -oL gh pr view'
expect 2 'command gh pr view'
expect 2 'builtin gh pr view'
expect 2 'noglob gh pr view'
expect 2 'xargs git push'
expect 2 'exec git push'
expect 2 'ionice gh pr view'
expect 2 '\git push'
expect 2 'git push & env -u CLAUDE_CODE_CHILD_SESSION git push origin HEAD:main'
expect 2 'gh pr view &'
# An unquoted mention as an argument is refused too; the message says to quote it.
expect 2 'rg gh README.md'
expect 2 'cd /repo && git push'
expect 2 'cd /repo/ && gh pr view'
expect 2 'git clone https://github.com/x/y /tmp/claude/y'
expect 2 'git clone --depth 1 https://github.com/x/y ~/y'
expect 2 'git clone https://github.com/x/y ../y'
expect 2 $'gh\tpr view | cat'
# Long enough to overflow a pipe buffer after an early match.
expect 2 "git push${nl}$(printf 'echo %0100d\n' $(seq 1000))"

expect 0 'git push'
expect 0 'git push 2>&1'
expect 0 'git push >&2'
expect 0 'git clone https://github.com/x/y'
expect 0 'git clone --depth 1 https://github.com/x/y y'
expect 0 'git clone git@github.com:x/y.git sub/y'
expect 0 'command -v gh'
expect 0 'command -V gh'
expect 0 'git push origin cd'
expect 0 "rg 'gh' README.md"
expect 0 'git fetch-pack x'
expect 0 'git pushx'
expect 0 'nice make lint'
expect 0 'time mise run lint'
expect 0 'git pull | tail'
expect 0 'git submodule update | tail'
expect 0 'git -C /x status'
expect 0 'git log --oneline > log.txt'
expect 0 'gh api repos/x -f title=a'
expect 0 'FOO=1 git status'
expect 0 'environment-check gh-like'
expect 0 "gh pr create --body \"a | b; c${nl}d\""
expect 0 "gh pr create --body \"say \\\"a | b\\\" here\""
expect 0 "gh api repos/x --jq '.[] | .name'"
expect 0 "gh api repos/x --jq '.[] | select(.n > 1)'"
expect 0 "gh api repos/x --jq \"it's | fine\""
expect 0 "rg 'git push' README.md | head"
expect 0 'git status | head'
expect 0 'git log --oneline | head -5'
expect 0 'echo high | cat'

[ "$rc" -eq 0 ] && echo 'block-piped-excluded_test: ok'
exit $rc
