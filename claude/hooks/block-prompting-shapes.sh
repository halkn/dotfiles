#!/usr/bin/env bash
# PreToolUse(Bash): refuse command shapes that permissions.blockReadsOutsideWorkingDirectories turns
# into a permission prompt even in auto mode, when a file tool or another plain form does the job.
#
# The hook runs before that prompt, so a refusal costs one retry instead of a human approval. Only
# shapes with a mechanical replacement are listed. Reads that need an outside path, and shapes this
# cannot tell apart from them (a path under ~/.claude, a path held in a variable), are left to the
# prompt.
set -euo pipefail

raw="$(jq -r '.tool_input.command // ""')"

# Words inside quotes are data (`rg 'sed -i'`, `git commit -m "cd x"`), so the command-name rules
# match against the command with quoted strings emptied.
read -r -d '' strip <<'JQ' || true
gsub("'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\""; "''")
JQ
unquoted="$(jq -Rrs "${strip}" <<<"${raw}")"

s='[[:space:]]'
at=$'(^|[;&|(\n])'"${s}*"
xargs="(xargs(${s}+-[^[:space:]]+)*${s}+)?"
in_place="${at}${xargs}(sed|perl)(${s}+[^;&|[:space:]]+)*${s}+(-[[:alpha:]]*i|--in-place)"
cd_cmd="${at}(cd|pushd)(${s}|$)"
# A sed script that opens with an address range is read as a path.
address="${at}${xargs}sed${s}[^;&|]*['\"][0-9,\$]*/"
temp_path='\$\{?TMPDIR|/tmp/claude-'
# gh reads a --body-file / -F path outside the sandbox without the prompt.
bare_gh="^${s}*gh${s}"

refuse() {
  printf '%s\n' "$1" >&2
  exit 2
}

if [[ "${unquoted}" =~ ${in_place} ]]; then
  refuse '`sed -i` / `perl -i` での書き換えは、作業ディレクトリの中でも確認になることが多いため止めました。
1 箇所の書き換えは Edit tool、複数箇所の同じ形の書き換えは `ast-grep run -p <pattern> -r <rewrite> -l <lang>` で行ってください。'
fi

if [[ "${raw}" =~ ${address} ]]; then
  refuse 'sed の `/re/` アドレスはパスとみなされて確認になるため止めました。
行範囲の抜き出しは `rg -n -A <行数> <pattern> <file>` か、Read tool の offset / limit で行ってください。'
fi

if [[ "${unquoted}" =~ ${cd_cmd} ]]; then
  refuse '`cd` は shell parser が追えなくなり確認になるため止めました。
作業ディレクトリからの相対パスで指定してください。cwd が要るツールには `go -C`・`cargo --manifest-path`・`git -C`（push・fetch・clone・ls-remote を除く）などを使ってください。'
fi

if [[ "${raw}" =~ ${temp_path} ]] && ! [[ "${unquoted}" =~ ${bare_gh} ]]; then
  refuse 'scratchpad・`$TMPDIR` は作業ディレクトリの外にあり、Bash のコマンドに書くと確認になるため止めました。
scratchpad のファイルは Read / Write / Edit tool で扱い、Bash の出力はファイルに書かずパイプで絞ってください。Bash で読み書きするファイルが要るなら、作業ディレクトリの `.scratch/<テーマ>/` に置いて相対パスで渡してください。`gh` の `--body-file` / `-F` には scratchpad の絶対パスを渡せます。'
fi

exit 0
