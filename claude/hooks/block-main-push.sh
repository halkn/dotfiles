#!/usr/bin/env bash
# PreToolUse(Bash) hook: main/master ブランチへの直接 push を確認させる。
#
# permissions.ask の `Bash(git push * main*)` 等は "main" の直前にスペースを
# 要求する文字列パターンマッチのため、コロン refspec
# （`git push origin HEAD:main`）や空 refspec 削除（`git push origin :main`）、
# `--all` など、コマンド文字列に " main"/" master" というトークンを含まない
# push で回避できる。ここでは push コマンドを実際に解釈し、送信先ブランチ名を
# 解決してから判定する。`--mirror` は強制 push 相当（ローカルに無い remote ref
# を削除しうる）とみなし、既存の force push 向け deny ポリシーに合わせて
# ハード拒否する。
#
# macOS 標準の /bin/bash は 3.2 系のため、空配列 + `set -u` の組み合わせで
# unbound variable になる既知の不具合がある。配列は使わず単一変数と
# 逐次処理で組み立てる（block-python.sh / block-secret-read.sh と同じ方針）。
#
# `cd X && git push` のようにセグメント間で作業ディレクトリが変わるケースは
# 追跡しない（block-python.sh / block-secret-read.sh と同じ既知の簡略化）。
set -euo pipefail

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

deny() {
	echo "$1" >&2
	exit 2
}

is_protected_branch() {
	case "$1" in
	main | master) return 0 ;;
	*) return 1 ;;
	esac
}

# refspec（`<src>:<dst>` または `<ref>`）の送信先ブランチが main/master なら ask する。
check_refspec() {
	local refspec="$1" dst
	case "$refspec" in
	*:*) dst="${refspec#*:}" ;;
	*) dst="$refspec" ;;
	esac
	[ -n "$dst" ] || return 0
	dst="${dst#refs/heads/}"
	if is_protected_branch "$dst"; then
		ask "main/master への直接 push（refspec: ${refspec}）を実行してよいですか?"
	fi
}

run_git() {
	if [ -n "$git_dir" ]; then
		git -C "$git_dir" "$@"
	else
		git "$@"
	fi
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
	[ "$base" = "git" ] || continue
	shift

	# git のグローバルオプションを読み飛ばし、サブコマンドまで進める。
	git_dir=""
	while [ "$#" -gt 0 ]; do
		case "$1" in
		-C)
			git_dir="${2:-}"
			shift 2
			;;
		-c)
			shift 2
			;;
		push) break ;;
		-*) shift ;;
		*) break ;;
		esac
	done
	[ "${1:-}" = "push" ] || continue
	shift

	mirror=0
	all=0
	saw_remote=0
	saw_refspec=0
	while [ "$#" -gt 0 ]; do
		case "$1" in
		--)
			shift
			while [ "$#" -gt 0 ]; do
				if [ "$saw_remote" -eq 0 ]; then
					saw_remote=1
				else
					saw_refspec=1
					check_refspec "$1"
				fi
				shift
			done
			;;
		--mirror)
			mirror=1
			shift
			;;
		--all)
			all=1
			shift
			;;
		-o | --push-option)
			shift 2
			;;
		-*) shift ;;
		*)
			if [ "$saw_remote" -eq 0 ]; then
				saw_remote=1
			else
				saw_refspec=1
				check_refspec "$1"
			fi
			shift
			;;
		esac
	done

	if [ "$mirror" -eq 1 ]; then
		deny "git push --mirror は main/master を含む全 ref に強制的に影響する（リモートにしか無い ref の削除もありうる）ため禁止です。個別ブランチを指定して push してください。"
	fi

	if [ "$all" -eq 1 ]; then
		if run_git rev-parse --verify --quiet refs/heads/main >/dev/null 2>&1 ||
			run_git rev-parse --verify --quiet refs/heads/master >/dev/null 2>&1; then
			ask "git push --all はローカルの main/master ブランチも含めて push します。実行してよいですか?"
		fi
		continue
	fi

	# 明示的な refspec が一つも無かった場合（`git push` / `git push origin`）は
	# 現在のブランチが送信先になる。
	if [ "$saw_refspec" -eq 0 ]; then
		branch="$(run_git branch --show-current 2>/dev/null || true)"
		if [ -n "$branch" ] && is_protected_branch "$branch"; then
			ask "現在のブランチ ($branch) は main/master です。main/master への直接 push を実行してよいですか?"
		fi
	fi
done <<EOF
$segments
EOF

exit 0
