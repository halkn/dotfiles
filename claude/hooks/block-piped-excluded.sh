#!/usr/bin/env bash
# PreToolUse(Bash): refuse an excludedCommands entry that is not a simple command.
#
# `sandbox.excludedCommands` takes a command out of the sandbox only when it stands alone.
# Put the same command in a pipeline, a list or a command substitution and the whole line
# runs sandboxed, where `gh` has no config and git has no CA bundle, so it fails with a TLS
# or config error that reads like an environment limit rather than like the shape of the
# command. The docs state this for `pbcopy` / `xclip` / `wl-copy` only, and the matching rule
# itself is not documented, so there is no pattern that fixes it in settings.json. Refusing
# the shape is what is left.
#
# Measured on Claude Code 2.1.280 (macOS): a leading `cd <dir> &&`, redirections, and `|`,
# `;` or newlines inside quotes keep the exclusion; `|`, `&&`, `;`, a newline and `$(...)`
# outside quotes drop it. A lone `&`, subshells and `git -C <dir> push` were not measured
# and are let through.
#
# It matches on the excluded commands, which are a closed set kept in step with
# `sandbox.excludedCommands`, rather than on shell syntax, which is not.
set -euo pipefail

# Drops one leading `cd <dir> &&` and the contents of quoted strings, keeping `$(` and
# backquotes from double-quoted ones since those still substitute.
read -r -d '' filter <<'JQ' || true
.tool_input.command // ""
| sub("^\\s*cd\\s+(\"[^\"]*\"|'[^']*'|[^\\s|;&]+)\\s*&&\\s*"; "")
| gsub("(?<q>'[^']*'|\"(?:[^\"\\\\]|\\\\.)*\")";
    if (.q | startswith("\"")) and (.q | test("\\$\\(|`")) then "$(" else "''" end)
JQ
command="$(jq -r "$filter")"

# Mirrors sandbox.excludedCommands in claude/settings.json; update both together.
excluded='git (push|fetch|pull|clone|ls-remote|submodule)|git remote (update|prune)|gh |hunk session '

is_compound() {
  [[ "$command" == *$'\n'* ]] && return 0
  printf '%s' "$command" | grep -Eq '\||&&|;|\$\(|`|[<>]\('
}

if printf '%s' "$command" | grep -Eq "(^|[^[:alnum:]_-])($excluded)" && is_compound; then
  cat >&2 <<'MSG'
git / gh / hunk session をパイプや複合コマンドに入れないでください。

sandbox.excludedCommands は単体のコマンドにしか効きません。パイプ・`&&`・`;`・改行・コマンド置換に
入れると行全体が sandbox 内で実行され、CA バンドル（/etc/ssl/cert.pem）や gh の設定に届かず、
TLS エラーや設定読取エラーになります。環境の制約に見えますが、コマンドの形の問題です。

裸で実行してください（先頭の `cd <dir> &&` とリダイレクトは使えます）。出力を絞りたい場合も、
まず裸で実行してから結果を読んでください。
MSG
  exit 2
fi

exit 0
