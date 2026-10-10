#!/usr/bin/env bash
# Tests for claude/hooks/block-secret-read.sh: the exit code it returns for a Bash tool call.
# Run with `mise run test:scripts`.
set -uo pipefail

hooks="$(CDPATH= cd -- "$(dirname -- "$0")/../../claude/hooks" && pwd)"
cwd=/repo
rc=0

# run <hook> <command>: prints the hook's stdout, returns its exit code.
run() {
  jq -n --arg c "$2" --arg d "$cwd" '{cwd: $d, tool_input: {command: $c}}' | bash "$hooks/$1" 2>/dev/null
}

fail() {
  printf 'FAIL %s: want %s, got %s: %.80s\n' "$1" "$2" "$3" "$4" >&2
  rc=1
}

nl=$'\n'

# expect_secret <exit code> <command>
expect_secret() {
  local got
  run block-secret-read.sh "$2" >/dev/null
  got=$?
  [ "$got" -eq "$1" ] || fail block-secret-read.sh "$1" "$got" "$2"
}

pad="$(printf 'echo %0100d\n' $(seq 1000))"

expect_secret 2 'cat ~/.azure/x'
expect_secret 2 'ls ~/.azure'
expect_secret 2 'ls ~/.snowflake/'
expect_secret 2 'cat ~/.snowsql/config'
expect_secret 2 'cat ~/.config/gh/hosts.yml'
expect_secret 2 'cat ~/.config/snowflake/config.toml'
expect_secret 2 'cat ~/.azure;true'
expect_secret 2 "cd ~${nl}cat .azure/x"
expect_secret 2 "ls ~/.azure${nl}true"
expect_secret 2 'cat ~/".azure"/x'
expect_secret 2 "cat ~/'.config/gh'/hosts.yml"
expect_secret 2 'cat ~/.config//gh/hosts.yml'
expect_secret 2 'cat ~/.config/./gh/hosts.yml'
expect_secret 2 'cat ~/.config/././snowflake/x'
expect_secret 2 'echo $AZURE_X'
expect_secret 2 'echo ${GH_TOKEN}'
expect_secret 2 'echo $GITHUB_TOKEN'
expect_secret 2 'echo $SNOWFLAKE_PASSWORD'
expect_secret 2 'echo $SNOWSQL_PWD'
# Long enough to overflow a pipe buffer after an early match.
expect_secret 2 "cat ~/.azure/x${nl}${pad}"
expect_secret 2 "echo \$AZURE_X${nl}${pad}"
expect_secret 2 "cat ~/.config/./gh/hosts.yml${nl}${pad}"

expect_secret 0 'curl https://management.azure.com/x'
expect_secret 0 'ls ~/.config/ghostty'
expect_secret 0 'ls ~/.azurex'
expect_secret 0 'echo $HOME $GHOST'
expect_secret 0 'mise run lint'
expect_secret 0 "mise run lint${nl}${pad}"

[ "$rc" -eq 0 ] && echo 'block-secret-read_test: ok'
exit $rc
