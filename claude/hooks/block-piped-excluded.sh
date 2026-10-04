#!/usr/bin/env bash
# PreToolUse(Bash): refuse an excludedCommands entry in a call shape the hooks cannot rely on.
#
# Two kinds of shape are refused:
#
# - Shapes that keep the call sandboxed: a pipeline, a list, a newline, a command substitution, a
#   redirection to or from a file, a `cd`, git's global options before the subcommand, and a
#   `git clone` into an absolute, `~` or `..` path. `gh` has no config there and github.com is not
#   an allowed host, so the call fails with an error that reads like an environment limit.
# - A wrapper or an assignment in front, which the exclusion looks through, so the call still runs
#   unsandboxed while hiding what it changes: `nice env -u CLAUDE_CODE_CHILD_SESSION git push`
#   leaves the pre-push hook unable to tell the push comes from Claude Code.
#
# The measured shapes are in docs/claude-code.md. It matches on the excluded commands, which are a
# closed set kept in step with `sandbox.excludedCommands`, rather than on shell syntax, which is not.
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
excluded="(^|[^[:alnum:]_-])(git${s}${network}|gh${s})"
git_opts="(^|[^[:alnum:]_-])git(${s}-[^[:space:]]+(${s}[^-[:space:]][^[:space:]]*)?)+${s}${network}([[:space:]]|$)"
compound=$'\n|\\||&&|;|\\$\\(|`|[<>]'
# The wrappers Claude Code strips before matching a Bash rule, and `env`, which it also looks past.
wrapper="(env|nice|time|timeout|nohup|stdbuf|command|builtin|noglob|xargs)"
prefixed="^[[:space:]]*(${wrapper}|[A-Za-z_][A-Za-z0-9_]*=[^[:space:]]*)([[:space:]]+[^[:space:]]+)*${s}(git${s}${network}|gh)([[:space:]]|$)"
# `command -v` looks a command up instead of running it, and the matcher does not strip it.
lookup="^[[:space:]]*command${s}-[vV]([[:space:]]|$)"
clone_path="(^|[^[:alnum:]_-])git${s}clone(${s}[^[:space:]]+)*${s}(/|~|([^[:space:]]*/)?[.][.](/|[[:space:]]|$))"

# Matched in-process: `printf | grep -q` under pipefail reads an early match on a long
# command as no match, since grep exits and printf dies of SIGPIPE.
if [[ "$command" =~ $git_opts ]] || [[ "$command" =~ $clone_path ]] ||
  { [[ "$command" =~ $prefixed ]] && ! [[ "$command" =~ $lookup ]]; } ||
  { [[ "$command" =~ $excluded ]] && [[ "$command" =~ $compound ]]; }; then
  cat >&2 <<'MSG'
git / gh を、sandbox の除外が当てにできない形で実行しようとしています。

sandbox.excludedCommands は単体のコマンドにしか効きません。パイプ・`&&`・`;`・改行・コマンド置換、
ファイルへのリダイレクト（`2>/dev/null` を含む）、`cd`、`git -C` などサブコマンドの前のオプション、
絶対パス・`~`・`..` を含む `git clone` の行き先のどれかがあると、行全体が sandbox 内で実行されます。
GitHub への通信（sandbox の許可先に無い）や gh の設定に届かず、プロキシの接続拒否（CONNECT 403）や
設定読取エラーになります。環境の制約に見えますが、コマンドの形の問題です。

`env`・`nice`・`time`・`command` などの wrapper や `VAR=…` の前置きも使えません。除外がこれらを
読み飛ばして sandbox の外で動かすため、push の判定（pre-push）を外せてしまうからです。

作業ディレクトリで裸のまま実行してください（`2>&1` は使えます）。他のリポジトリの GitHub 操作は
`gh -R <owner>/<repo>` で行えます。clone は作業ディレクトリの中への相対パスにするか、`gh repo clone` を
使ってください。出力を絞るときは `--json` / `--jq` などツール自身のオプションを使うか、まず裸で実行して
から結果を読んでください。複数行の本文は `$(cat <<EOF ...)` やリダイレクトではなく、Write tool で
`.scratch/` に書いたファイルを `--body-file` / `-F` で渡してください。
MSG
  exit 2
fi

exit 0
