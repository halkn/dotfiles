#!/usr/bin/env bash
# PreToolUse(Bash): refuse an excludedCommands entry in a call shape the sandbox exclusion does not
# reliably keep.
#
# The exclusion holds only for a bare command. Anything in front of it, a pipeline, a list, a
# newline, a command substitution, a redirection to or from a file, git's global options before the
# subcommand, or a `git clone` into an absolute, `~` or `..` path either keeps the call sandboxed,
# where `gh` has no config and github.com is not an allowed host, or runs it unsandboxed with an
# environment the pre-push hook cannot trust.
#
# It matches on the excluded commands, which are a closed set kept in step with
# `sandbox.excludedCommands`, rather than on shell syntax, which is not.
set -euo pipefail

# Drops the contents of quoted strings (keeping `$(` and backquotes from double-quoted ones since
# those still substitute) and descriptor duplications such as `2>&1`.
read -r -d '' filter <<'JQ' || true
.tool_input.command // ""
| gsub("(?<q>'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\")";
    if (.q | startswith("\"")) and (.q | test("\\$\\(|`")) then "$(" else "''" end)
| gsub("[<>]&[0-9-]"; "")
JQ
command="$(jq -r "$filter")"

# Mirrors sandbox.excludedCommands in claude/settings.json; update both together.
s='[[:space:]]+'
network="(push|fetch|clone|ls-remote|remote${s}(update|prune))"
target="(git${s}${network}([^[:alnum:]_-]|$)|gh${s})"
excluded="(^|[^[:alnum:]_-])${target}"
bare="^[[:space:]]*${target}"
git_opts="(^|[^[:alnum:]_-])git(${s}-[^[:space:]]+(${s}[^-[:space:]][^[:space:]]*)?)+${s}${network}([[:space:]]|$)"
compound=$'\n|\\||&|;|\\$\\(|`|[<>]'
clone_path="(^|[^[:alnum:]_-])git${s}clone(${s}[^[:space:]]+)*${s}(/|~|([^[:space:]]*/)?[.][.](/|[[:space:]]|$))"

# Matched in-process: `printf | grep -q` under pipefail reads an early match on a long
# command as no match, since grep exits and printf dies of SIGPIPE.
if [[ "$command" =~ $git_opts ]] || [[ "$command" =~ $clone_path ]] ||
  { [[ "$command" =~ $excluded ]] && { ! [[ "$command" =~ $bare ]] || [[ "$command" =~ $compound ]]; }; }; then
  cat >&2 <<'MSG'
git / gh を、sandbox の除外が当てにできない形で実行しようとしています。

sandbox.excludedCommands は、行頭に裸で置いた単体のコマンドにしか確実には効きません。前置き
（`cd`・`env`・`nice`・`VAR=…` など）、パイプ・`&`・`&&`・`;`・改行・コマンド置換、ファイルへのリダイレクト
（`2>/dev/null` を含む）、`git -C` などサブコマンドの前のオプション、絶対パス・`~`・`..` を含む
`git clone` の行き先があると、sandbox 内で動いて GitHub や gh の設定に届かない（CONNECT 403 や設定
読取エラーになる）か、push の判定（pre-push）を当てにできない環境で動きます。

作業ディレクトリで裸のまま実行してください（`2>&1` は使えます）。他のリポジトリの GitHub 操作は
`gh -R <owner>/<repo>` で行えます。clone は作業ディレクトリの中への相対パスにするか、`gh repo clone` を
使ってください。出力を絞るときは `--json` / `--jq` などツール自身のオプションを使うか、まず裸で実行して
から結果を読んでください。複数行の本文は `$(cat <<EOF ...)` やリダイレクトではなく、Write tool で
`.scratch/` に書いたファイルを `--body-file` / `-F` で渡してください。

git / gh を実行せず引数として書いただけ（`rg gh README.md` など）なら、その語を引用符で囲めば通ります。
MSG
  exit 2
fi

exit 0
