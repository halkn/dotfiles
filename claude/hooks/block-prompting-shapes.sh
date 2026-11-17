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
# match against the command with quoted strings emptied. A variable is data only inside single
# quotes (`rg '$TMPDIR'`); "$TMPDIR/x" still expands.
read -r -d '' strip <<'JQ' || true
gsub("(?<q>'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\")"; if $all or (.q | startswith("'")) then "''" else .q end)
JQ
unquoted="$(jq -Rrs --argjson all true "${strip}" <<<"${raw}")"
unquoted_single="$(jq -Rrs --argjson all false "${strip}" <<<"${raw}")"

s='[[:space:]]'
nl=$'\n'
at="(^|[;&|({${nl}]|(then|do|else)${s}|-exec(dir)?${s})${s}*"
prefix="([[:alpha:]_][[:alnum:]_]*=[^[:space:]]*${s}+)*(xargs(${s}+-[^[:space:]]+)*${s}+)?"
# Only clusters of flags that take no argument, so perl's `-Mstrict` is not read as `-i`.
in_place="${at}${prefix}(sed|perl)(${s}+[^;&|[:space:]]+)*${s}+(-[EnrsuzplawF]*i|--in-place)"
cd_cmd="${at}${prefix}(cd|pushd)(${s}|$)"
# A sed script that opens with an address range (`/re/` or `\#re#`) is read as a path.
address="${at}${prefix}sed${s}[^;&|${nl}]*['\"][0-9,\$]*(/|\\\\)"
temp_var='\$\{?TMPDIR'
temp_path="(^|[[:space:]=:'\"<>])(/private)?/tmp/claude[-/]"
# gh reads an absolute --body-file / -F path outside the sandbox without the prompt. $TMPDIR is
# refused for gh too, since it expands to another directory outside the sandbox.
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

if [[ "${unquoted_single}" =~ ${temp_var} ]] ||
  { [[ "${raw}" =~ ${temp_path} ]] && ! [[ "${unquoted}" =~ ${bare_gh} ]]; }; then
  refuse 'scratchpad・`$TMPDIR` は作業ディレクトリの外にあり、Bash のコマンドに書くと確認になるため止めました。
scratchpad のファイルは Read / Write / Edit tool で扱い、Bash の出力はファイルに書かずパイプで絞ってください。Bash で読み書きするファイルが要るなら、作業ディレクトリの `.scratch/<テーマ>/` に置いて相対パスで渡してください。`gh` の `--body-file` / `-F` には scratchpad の絶対パスを渡せます（`$TMPDIR` は `gh` の動く sandbox の外では別の場所を指すので使えません）。'
fi

exit 0
