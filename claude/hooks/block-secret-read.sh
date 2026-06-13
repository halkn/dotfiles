#!/usr/bin/env bash
# PreToolUse(Bash) hook: Azure / Snowflake / GitHub(gh) の認証情報の読み取り・漏洩を拒否する。
#
# sandbox の allowRead は `az`/`gh` 本体の token cache 読取を許すために `~/.azure`・
# `~/.config/gh` を開けており、プロセスを区別しないため `cat ~/.azure/...` や
# `cat ~/.config/gh/hosts.yml` も素通りしてしまう。
# `az`/`gh` 等の正規コマンドは通しつつ、認証情報そのものの読取/展開だけを止める。
#
# 二段で検査する:
#   A. 読取系コマンド（cat 等）が機微パス（.azure / .snowflake / .snowsql /
#      .config/gh）を引数に取るセグメントを拒否する。`echo $(cat ~/.azure/x)` の
#      ような コマンド置換も、置換境界を区切りに畳み込むことで cat 側で捕捉する。
#   B. 機微 env（$AZURE_* / $SNOWFLAKE_* / $SNOWSQL_* / $GH_* / $GITHUB_*）の参照を
#      含むコマンドを拒否する。echo / printf などでの値の展開（transcript への漏洩）を防ぐ。
set -euo pipefail

command="$(jq -r '.tool_input.command // ""')"

deny() {
	echo "$1" >&2
	exit 2
}

# B: 機微 env の参照（$AZURE_FOO / ${SNOWFLAKE_BAR} / $GH_TOKEN 等）を含むなら拒否する。
if printf '%s' "$command" | grep -Eq '\$\{?(AZURE|SNOWFLAKE|SNOWSQL|GH|GITHUB)_'; then
	deny "Azure/Snowflake/GitHub の認証系環境変数の展開は禁止です（値が transcript に漏洩するため）。設定値は az / snowflake / gh CLI のサブコマンド経由で扱ってください。"
fi

# コマンド置換とサブシェルを開く記号を改行に変換してから、
# パイプ・順次・論理演算子などの区切りを改行へ畳み込みセグメント化する。
segments="$(printf '%s' "$command" | sed -E 's/\$\(/\n/g; s/`/\n/g' | tr '|;&()' '\n\n\n\n\n')"

is_reader() {
	# 与えられたプログラム名（basename 済み・小文字化済み）が中身を吐く読取系か。
	case "$1" in
	cat | tac | nl | less | more | head | tail | xxd | od | hexdump | strings | base64 | cut | grep | egrep | fgrep | rg | sed | awk | sort | uniq | jq | yq | dd) return 0 ;;
	*) return 1 ;;
	esac
}

set -f # セグメント分割時のグロブ展開を無効化する
while IFS= read -r seg; do
	# shellcheck disable=SC2086
	set -- $seg
	# 先頭の環境変数代入とラッパーコマンドを読み飛ばし、実行対象まで進める。
	while [ "$#" -gt 0 ]; do
		case "$1" in
		*=*) shift ;;
		sudo | env | nohup | time | exec | command | builtin | watch | xargs | stdbuf | nice | ionice) shift ;;
		*) break ;;
		esac
	done
	prog="${1:-}"
	base="${prog##*/}"
	base="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
	if is_reader "$base"; then
		# A: 読取系セグメントが機微パスを引数に含むなら拒否する。
		if printf '%s' "$seg" | grep -Eq '(\.(azure|snowflake|snowsql)|\.config/gh)(/|\b)'; then
			deny "Azure/Snowflake/GitHub の認証情報（~/.azure・~/.snowflake・~/.snowsql・~/.config/gh）の読み取りは禁止です。認証は az / snowflake / gh CLI 経由で行ってください。"
		fi
	fi
done <<EOF
$segments
EOF

exit 0
