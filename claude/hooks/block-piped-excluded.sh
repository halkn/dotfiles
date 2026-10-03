#!/usr/bin/env bash
# PreToolUse(Bash): refuse an excludedCommands entry in a call shape that keeps it sandboxed.
#
# `sandbox.excludedCommands` takes a call out of the sandbox only in some shapes. In any other
# shape the whole call runs sandboxed, where `gh` has no config and github.com is not an allowed
# host, so it fails with a proxy or config error that reads like an environment limit rather than
# like the shape of the command. Refusing the shape up front turns that failure into an instruction.
#
# Measured on Claude Code 2.1.288 (macOS): `|`, `&&`, `;`, a newline, `$(...)`, a redirection to or
# from a file (`2>/dev/null` included), `git -C <dir>` before the subcommand, and a `cd` into any
# directory other than the working directory drop the exclusion. `2>&1`, a `cd` into the working
# directory, and `|`, `;` or newlines inside quotes keep it. A lone `&` and subshells were not
# measured and are let through.
#
# It matches on the excluded commands, which are a closed set kept in step with
# `sandbox.excludedCommands`, rather than on shell syntax, which is not.
set -euo pipefail

# Drops a leading `cd <working directory> &&`, the contents of quoted strings (keeping `$(` and
# backquotes from double-quoted ones since those still substitute) and descriptor duplications
# such as `2>&1`.
read -r -d '' filter <<'JQ' || true
(.cwd // "" | sub("/+$"; "")) as $cwd
| .tool_input.command // ""
| (capture("^\\s*cd\\s+(?<dir>/[^\\s|;&$`'\"~]*)\\s*&&\\s*") // {dir: null}) as $cd
| if $cwd != "" and $cd.dir != null and ($cd.dir | sub("/+$"; "")) == $cwd
  then sub("^\\s*cd\\s+/[^\\s|;&$`'\"~]*\\s*&&\\s*"; "")
  else . end
| gsub("(?<q>'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\")";
    if (.q | startswith("\"")) and (.q | test("\\$\\(|`")) then "$(" else "''" end)
| gsub("[<>]&[0-9-]"; "")
JQ
command="$(jq -r "$filter")"

# Mirrors sandbox.excludedCommands in claude/settings.json; update both together.
s='[[:space:]]+'
network="(push|fetch|clone|ls-remote|remote${s}(update|prune))"
excluded="(^|[^[:alnum:]_-])(git${s}${network}|gh${s})"
# Global options before the subcommand keep even a lone command sandboxed.
git_opts="(^|[^[:alnum:]_-])git(${s}-[^[:space:]]+(${s}[^-[:space:]][^[:space:]]*)?)+${s}${network}([[:space:]]|$)"
compound=$'\n|\\||&&|;|\\$\\(|`|[<>]'

# Matched in-process: `printf | grep -q` under pipefail reads an early match on a long
# command as no match, since grep exits and printf dies of SIGPIPE.
if [[ "$command" =~ $git_opts ]] || { [[ "$command" =~ $excluded ]] && [[ "$command" =~ $compound ]]; }; then
  cat >&2 <<'MSG'
git / gh を、sandbox の除外が外れる形で実行しようとしています。

sandbox.excludedCommands は単体のコマンドにしか効きません。パイプ・`&&`・`;`・改行・コマンド置換、
ファイルへのリダイレクト（`2>/dev/null` を含む）、`git -C` などサブコマンドの前のオプション、
作業ディレクトリ以外への `cd` のどれかがあると、行全体が sandbox 内で実行されます。GitHub への通信
（sandbox の許可先に無い）や gh の設定に届かず、プロキシの接続拒否（CONNECT 403）や設定読取エラーになります。
環境の制約に見えますが、コマンドの形の問題です。

作業ディレクトリで裸のまま実行してください（`2>&1` は使えます）。他のリポジトリの GitHub 操作は
`gh -R <owner>/<repo>` で行えます。出力を絞るときは `--json` / `--jq` などツール自身のオプションを使うか、
まず裸で実行してから結果を読んでください。複数行の本文は `$(cat <<EOF ...)` やリダイレクトではなく、
Write tool で `.scratch/` に書いたファイルを `--body-file` / `-F` で渡してください。
MSG
  exit 2
fi

exit 0
