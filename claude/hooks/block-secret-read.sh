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
# `expand file`・`while read` リダイレクトで抜けられる）のに対し、守る対象のパスと
# 環境変数名は閉じているので、コマンド文字列全体へのマッチで検査する。az / gh /
# snowflake CLI の正規の呼び出しはこれらのパスを引数に書かないため巻き込まれない。
#
# ただし、守る対象が閉じていても「その対象の綴り方」は閉じていない。表記のゆれ
# （クォート・重複スラッシュ・`/./`・先頭 `./`）は下の正規化で畳むが、パスを分割する形
# （`cd ~/.config && cat gh/hosts.yml`）や変数経由（`d=~/.azure; cat $d/config`）は
# 素通りする。これは決定論的なガードの上限で、ここから先は sandbox 側で塞ぐしかない
# （`allowRead` を `~/.config` から必要なサブディレクトリへ絞って `~/.config/gh` を外す）。
# この hook は sandbox に残った穴を埋める二次防御であって、単独の境界ではない。
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
	deny "Azure/Snowflake/GitHub の認証情報（~/.azure・~/.snowflake・~/.snowsql・~/.config/gh・~/.config/snowflake）への参照は禁止です。認証は az / snowflake / gh CLI 経由で行ってください。"
}

# 機微 env（$AZURE_FOO / ${SNOWFLAKE_BAR} / $GH_TOKEN 等）の展開。
# sandbox.credentials.envVars の `mode: "deny"` が一次防御だが、excludedCommands
# （`gh *` 等）は sandbox の外を走るためここでも押さえる。
if printf '%s' "$command" | grep -Eq '\$\{?(AZURE|SNOWFLAKE|SNOWSQL|GH|GITHUB)_'; then
	deny "Azure/Snowflake/GitHub の認証系環境変数の展開は禁止です（値が transcript に漏洩するため）。設定値は az / snowflake / gh CLI のサブコマンド経由で扱ってください。"
fi

# 同じパスを指す表記のゆれを畳んでから照合する。クォート（`"$HOME"/.azure`・
# `~/".azure"`）・重複スラッシュ（`~//.azure`）・`/./`・先頭の `./` はいずれも
# シェルにとって等価だが、素の文字列照合では別物になる。
normalized="$(printf '%s' "$command" | tr -d "\"'" | sed -E 's#/{2,}#/#g')"
# `/././` のような重なりがあるため収束するまで畳む。BSD sed はワンライナーの
# ラベル分岐（`:a; ...; ta`）を解さないので、ループはシェル側に置く。
while printf '%s' "$normalized" | grep -q '/\./'; do
	normalized="$(printf '%s' "$normalized" | sed -E 's#/\./#/#g')"
done
normalized="$(printf '%s' "$normalized" | sed -E 's#(^|[[:space:]<>|;&=(])\./#\1#g')"

# 認証情報ストアへのパス参照。直前が英数字・アンダースコアの場合は除外する
# （`management.azure.com` のようなホスト名を巻き込まないため）。
if printf '%s' "$normalized" | grep -Eq '(^|[^[:alnum:]_])(\.(azure|snowflake|snowsql)|\.config/(gh|snowflake))(/|[[:space:];|&<>)]|$)'; then
	deny_path
fi

exit 0
