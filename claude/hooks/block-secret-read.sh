#!/usr/bin/env bash
# PreToolUse(Bash) hook: Azure / Snowflake / GitHub(gh) の認証情報への参照を拒否する。
#
# sandbox の allowRead は `az`/`gh` 本体の token cache 読取を許すために `~/.azure`・
# `~/.config`（`~/.config/gh` を含む）を開けており、プロセスを区別しない。
# `denyRead` は allowRead の内側では実効しない（`.claude/rules/claude-code.md` に実測記録）
# ため、この 2 箇所だけ sandbox の denyRead: ~/ に穴が開いたままになる。そこを塞ぐ。
#
# 判定は「読み取りに使うコマンド」ではなく「参照される資産」で行う。読取コマンドの
# 集合は開いていて列挙できない（`cat` を塞いでも `tr -d "" < file`・`perl -pe "" file`・
# `expand file`・`while read` リダイレクトで抜けられる）が、守る対象のパスと環境変数名は
# 閉じた集合なので、コマンド文字列全体へのマッチで検査する。az / gh / snowflake CLI の
# 正規の呼び出しはこれらのパスを引数に書かないため巻き込まれない。
#
# 副作用として、これらのパスを文字列として扱うだけのコマンド（例:
# `rg '~/.azure/' README.md`）も拒否される。誤検知時はパスを直書きしない形に書き換える。
set -euo pipefail

if command -v jaq >/dev/null 2>&1; then
	JQ_BIN=jaq
else
	JQ_BIN=jq
fi

command="$("$JQ_BIN" -r '.tool_input.command // ""')"

deny() {
	echo "$1" >&2
	exit 2
}

deny_path() {
	deny "Azure/Snowflake/GitHub の認証情報（~/.azure・~/.snowflake・~/.snowsql・~/.config/gh）への参照は禁止です。認証は az / snowflake / gh CLI 経由で行ってください。"
}

# 機微 env（$AZURE_FOO / ${SNOWFLAKE_BAR} / $GH_TOKEN 等）の展開。
# sandbox.credentials.envVars の `mode: "deny"` が一次防御だが、excludedCommands
# （`gh *` 等）は sandbox の外を走るためここでも押さえる。
if printf '%s' "$command" | grep -Eq '\$\{?(AZURE|SNOWFLAKE|SNOWSQL|GH|GITHUB)_'; then
	deny "Azure/Snowflake/GitHub の認証系環境変数の展開は禁止です（値が transcript に漏洩するため）。設定値は az / snowflake / gh CLI のサブコマンド経由で扱ってください。"
fi

store='\.(azure|snowflake|snowsql)|\.config/gh'

# home 起点の形: ~/.azure/... / $HOME/.azure / /Users/<user>/.config/gh
if printf '%s' "$command" | grep -Eq "(~|\\\$\{?HOME\}?|/Users/[^/[:space:]]+)/(${store})([/[:space:]\"']|$)"; then
	deny_path
fi

# `cd ~` 後を想定した相対形: .azure/... / .config/gh/...
if printf '%s' "$command" | grep -Eq "(^|[[:space:]<>|;&\"'=(])(${store})/"; then
	deny_path
fi

exit 0
