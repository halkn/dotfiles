#!/usr/bin/env bash
# PreToolUse(Bash) hook: YAML の確認・パース・問い合わせ目的で Python を
# 起動しようとする Bash コマンドを拒否する（JSON に対する jq のような用途を防ぐ）。
# パイプ経由（例: `cat x.yaml | python -c ...`）も検知する。
set -euo pipefail

command="$(jq -r '.tool_input.command // ""')"
lower="$(printf '%s' "$command" | tr '[:upper:]' '[:lower:]')"

# python / python3 の呼び出しを含むか（トークン境界で判定）
uses_python='(^|[^[:alnum:]_./])python3?([^[:alnum:]_]|$)'
# YAML への参照を含むか（拡張子 / import yaml / yaml.safe_load など）
refs_yaml='(import[[:space:]]+yaml|yaml\.|\.ya?ml([^[:alnum:]]|$)|[[:space:]]ya?ml([^[:alnum:]]|$))'

if printf '%s' "$lower" | grep -Eq "$uses_python" &&
	printf '%s' "$lower" | grep -Eq "$refs_yaml"; then
	echo "YAML の確認に Python を使わないでください。構文確認は yaml-language-server / just lint、値の確認は yq を使ってください。" >&2
	exit 2
fi

exit 0
