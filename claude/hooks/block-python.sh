#!/usr/bin/env bash
# PreToolUse(Bash) hook: Python の起動を含む Bash コマンドを拒否する。
# 任意コードを実行できるため、先頭一致の deny を回避するパイプ経由
# （例: `cat x | python -c ...`）やフルパス（例: `/usr/bin/python3`）、
# `uv run python ...` も対象にする。
#
# 引数やクォート内の文字列（例: `rg "python" README.md`）を巻き込まないよう、
# コマンド区切りで分割した各セグメントの「実行されるプログラム名」だけを見る。
# pytest / pyright / ipython 等の別コマンド、`uv run pytest` は許可する。
set -euo pipefail

command="$(jq -r '.tool_input.command // ""')"

# コマンド置換とサブシェルを開く記号を改行に変換してから、
# パイプ・順次・論理演算子などの区切りを改行へ畳み込みセグメント化する。
segments="$(printf '%s' "$command" | sed -E 's/\$\(/\n/g; s/`/\n/g' | tr '|;&()' '\n\n\n\n\n')"

is_python() {
	# 与えられたプログラム名（basename 済み・小文字化済み）が python 本体か。
	case "$1" in
	python | python[0-9]*) return 0 ;;
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
		uv)
			shift
			[ "${1:-}" = "run" ] && shift
			;;
		*) break ;;
		esac
	done
	prog="${1:-}"
	base="${prog##*/}"
	base="$(printf '%s' "$base" | tr '[:upper:]' '[:lower:]')"
	if is_python "$base"; then
		echo "Python の実行は禁止です（任意コード実行のため）。型/構文確認は専用 LSP・linter、値の確認は jq/yq、Python が必要な場合は uv の専用サブコマンドを使ってください。" >&2
		exit 2
	fi
done <<EOF
$segments
EOF

exit 0
