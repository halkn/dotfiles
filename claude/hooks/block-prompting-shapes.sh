#!/usr/bin/env bash
# PreToolUse(Bash): refuse command shapes that permissions.blockReadsOutsideWorkingDirectories turns
# into a permission prompt even in auto mode, when a file tool or another plain form does the job.
#
# The hook runs before that prompt, so a refusal costs one retry instead of a human approval. Only
# shapes with a mechanical replacement are listed. Reads that need an outside path, and shapes this
# cannot tell apart from them (a path under ~/.claude, a path held in a variable), are left to the
# prompt.
set -euo pipefail

# Words inside quotes are data (`rg 'sed -i'`, `git commit -m "cd x"`), so the command-name rules
# match against the command with quoted strings emptied. A variable is data only inside single
# quotes (`rg '$TMPDIR'`); "$TMPDIR/x" still expands.
# One jq run for all three forms, NUL-separated: the hook runs on every Bash call. A NUL inside
# the command would shift the fields, so it is dropped, as bash drops it from a $(...).
read -r -d '' split <<'JQ' || true
def strip($all): gsub("(?<q>'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\")"; if $all or (.q | startswith("'")) then "''" else .q end);
(.tool_input.command // "" | gsub("\u0000"; "")) | ., strip(true), strip(false) | ., "\u0000"
JQ
{
  IFS= read -r -d '' raw
  IFS= read -r -d '' unquoted
  IFS= read -r -d '' unquoted_single
} < <(jq -j "${split}")

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
# gh runs outside the sandbox, where the safety check prompts on a --jq that builds an array
# (`[.a, .b]`, `[.x[] | ...]`) but not on indexing (`.x[0]`, `.[]`, `.["k"]`). A `[` right after a
# name, `.`, `]` or `)` indexes; anywhere else it opens an array. Text inside jq strings
# (`"\(.title) [draft]"`) is not code, so jq_code blanks it out before the match.
jq_flag="${s}(--jq|-q)(=|${s})"
jq_arg="${s}(--jq|-q)(=|${s}+)('[^']*'|\"([^\"\\\\]|\\\\.)*\"|[^[:space:]'\"]+)"
jq_array="(^|[[:space:](|,+:])\\["
# A raw response is the file itself, so --jq fails on anything but a JSON file and costs a retry.
raw_accept='vnd\.github\.raw'
json_path="\\.json([?'\"[:space:]]|$)"

refuse() {
  printf '%s\n' "$1" >&2
  exit 2
}

# Print the jq program with string text replaced by `x`, keeping the code of `\(...)`. Each stack
# entry is `s` (inside a string) or the paren depth of a code level. Written for bash 3.2.
jq_code() {
  local q=$1 out='' ch top i=0 n=${#1}
  local -a stack=(0)
  while ((i < n)); do
    ch=${q:i:1}
    top=${stack[${#stack[@]}-1]}
    if [[ "${top}" == s ]]; then
      if [[ "${ch}" == '\' && "${q:i+1:1}" == '(' ]]; then
        stack+=(1)
        out+='('
        i=$((i + 1))
      elif [[ "${ch}" == '\' ]]; then
        out+='xx'
        i=$((i + 1))
      elif [[ "${ch}" == '"' ]]; then
        unset "stack[${#stack[@]} - 1]"
        out+='"'
      else
        out+='x'
      fi
    else
      case "${ch}" in
        '"')
          stack+=(s)
          ;;
        '(')
          stack[${#stack[@]} - 1]=$((top + 1))
          ;;
        ')')
          if ((top == 1 && ${#stack[@]} > 1)); then
            unset "stack[${#stack[@]} - 1]"
          elif ((top > 0)); then
            stack[${#stack[@]} - 1]=$((top - 1))
          fi
          ;;
      esac
      out+="${ch}"
    fi
    i=$((i + 1))
  done
  printf '%s' "${out}"
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

if [[ "${unquoted}" =~ ${bare_gh} ]] && [[ "${unquoted}" =~ ${jq_flag} ]]; then
  if [[ "${raw}" =~ ${raw_accept} ]] && ! [[ "${raw}" =~ ${json_path} ]]; then
    refuse '`Accept: application/vnd.github.raw` の応答はファイルそのもので、JSON ファイル以外に `--jq` を付けると失敗するため止めました。
`--jq` を外して本文をそのまま受け取ってください。'
  fi
  if [[ "${raw}" =~ ${jq_arg} ]]; then
    jq_prog=${BASH_REMATCH[3]}
    case "${jq_prog}" in
      \'*)
        jq_prog=${jq_prog:1:${#jq_prog}-2}
        ;;
      \"*)
        jq_prog=${jq_prog:1:${#jq_prog}-2}
        jq_prog=${jq_prog//\\\"/\"}
        ;;
    esac
  fi
  if [[ -n "${jq_prog-}" ]] && [[ "$(jq_code "${jq_prog}")" =~ ${jq_array} ]]; then
    refuse 'gh の `--jq` で配列を組む形（`[.a, .b]`・`[.x[] | …]`）は shell parser が追えず確認になるため止めました。
複数の値は文字列補間（`.[] | "\(.a)\t\(.b)"`）で並べ、配列の要素をまとめるときは `.x | map(.name) | join(",")` を使ってください。添字（`.x[0]`・`.[]`・`.sha[0:7]`）はそのまま使えます。'
  fi
fi

exit 0
