#!/usr/bin/env bash
# PreToolUse(Bash) hook: `gh pr create` の対象リポジトリが github.com/halkn
# 配下（個人アカウント）でない場合は確認させる。
#
# claude/settings.json の permissions.allow は `Bash(gh pr create*)` を無条件
# 許可しているが、settings.json はグローバル（symlink で ~/.claude/settings.json）
# のため、仕事用リポジトリ等 autoMode.environment が想定する信頼範囲外でも
# 無確認で発火してしまう。ここでは `--repo`/`-R` 指定、無ければ origin リモート
# から対象 owner を解決し、"halkn" 以外なら ask する。
#
# `cd X && gh pr create` のようにセグメント間で作業ディレクトリが変わる
# ケースは追跡しない（block-python.sh 等と同じ既知の簡略化）。origin 以外の
# remote 名を使っている場合や gh 自体の repo 解決ロジック（upstream tracking
# 等）との完全な一致も保証しない — 判定が付かない場合は安全側に倒して ask する。
set -euo pipefail

TRUSTED_OWNER="halkn"

if command -v jaq >/dev/null 2>&1; then
	JQ_BIN=jaq
else
	JQ_BIN=jq
fi

command="$("$JQ_BIN" -r '.tool_input.command // ""')"

ask() {
	"$JQ_BIN" -n --arg reason "$1" '{
		hookSpecificOutput: {
			hookEventName: "PreToolUse",
			permissionDecision: "ask",
			permissionDecisionReason: $reason
		}
	}'
	exit 0
}

# "git@github.com:OWNER/REPO.git" / "https://github.com/OWNER/REPO" /
# "OWNER/REPO"（--repo 省略形）のいずれからも owner を取り出す。
extract_owner() {
	local url="$1" rest owner
	case "$url" in
	*github.com[:/]*)
		rest="${url#*github.com[:/]}"
		owner="${rest%%/*}"
		;;
	*/*)
		owner="${url%%/*}"
		;;
	*)
		owner=""
		;;
	esac
	printf '%s' "$owner"
}

# コマンド置換とサブシェルを開く記号を改行に変換してから、
# パイプ・順次・論理演算子などの区切りを改行へ畳み込みセグメント化する。
segments="$(printf '%s' "$command" | sed -E 's/\$\(/\n/g; s/`/\n/g' | tr '|;&()' '\n\n\n\n\n')"

set -f # セグメント分割時のグロブ展開を無効化する
while IFS= read -r seg; do
	# shellcheck disable=SC2086
	set -- $seg

	# 先頭の環境変数代入とラッパーコマンドを読み飛ばす。
	while [ "$#" -gt 0 ]; do
		case "$1" in
		*=*) shift ;;
		sudo | env | nohup | time | exec | command | builtin | watch | xargs | stdbuf | nice | ionice) shift ;;
		*) break ;;
		esac
	done

	prog="${1:-}"
	base="${prog##*/}"
	[ "$base" = "gh" ] || continue
	shift

	[ "${1:-}" = "pr" ] || continue
	shift
	[ "${1:-}" = "create" ] || continue
	shift

	repo_flag=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--repo=*) repo_flag="${1#--repo=}" ;;
		--repo | -R) repo_flag="${2:-}" ;;
		esac
		shift
	done

	if [ -n "$repo_flag" ]; then
		owner="$(extract_owner "$repo_flag")"
	else
		origin_url="$(git config --get remote.origin.url 2>/dev/null || true)"
		owner="$(extract_owner "$origin_url")"
	fi

	if [ -z "$owner" ]; then
		ask "gh pr create の対象リポジトリの owner を特定できませんでした。実行してよいですか?"
	fi

	lower_owner="$(printf '%s' "$owner" | tr '[:upper:]' '[:lower:]')"
	if [ "$lower_owner" != "$TRUSTED_OWNER" ]; then
		ask "gh pr create の対象リポジトリ owner が \"${owner}\" です（信頼範囲は github.com/${TRUSTED_OWNER} 配下）。実行してよいですか?"
	fi
done <<EOF
$segments
EOF

exit 0
