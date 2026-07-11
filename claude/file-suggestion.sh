#!/usr/bin/env bash
# Claude Code の `@` ファイル補完を fd + fzf の fuzzy match に置き換える。
# stdin: {"query": "..."} / stdout: 改行区切りのファイルパス（先頭 15 件が使われる）
# fd / fzf は mise 管理（.config/mise/config.toml）。無い環境では rg / grep に落とす。
set -euo pipefail

if command -v jaq >/dev/null 2>&1; then
	JQ_BIN=jaq
else
	JQ_BIN=jq
fi

query="$("$JQ_BIN" -r '.query // ""' 2>/dev/null)" || query=""
cd "${CLAUDE_PROJECT_DIR:-.}"

list_files() {
	if command -v fd >/dev/null 2>&1; then
		timeout 2 fd --type f --hidden --exclude .git
	else
		timeout 2 rg --files --hidden
	fi
}

if [ -n "$query" ] && command -v fzf >/dev/null 2>&1; then
	filter=(fzf --filter "$query")
elif [ -n "$query" ]; then
	filter=(grep -iF -- "$query")
else
	filter=(cat)
fi
list_files | "${filter[@]}" | head -15 || true
