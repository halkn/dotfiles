#!/usr/bin/env bash
# PreToolUse(Bash): refuse references to Azure / Snowflake / GitHub credential stores.
#
# sandbox allowRead has to open ~/.azure and ~/.config so `az` and `gh` can read their own
# token caches, and a denyRead nested inside an allowRead does not take effect, so those two
# paths stay readable by any process. This hook covers that gap as a second line of defence,
# not as a boundary of its own: it matches on the protected assets, which are a closed set,
# rather than on reading commands, which are not. Splitting a path across segments
# (`cd ~/.config && cat gh/hosts.yml`) or going through a variable still gets past it.
# .claude/rules/claude-code.md records the measurements behind both points.
#
# Side effect: commands that only mention these paths as text (`rg '~/.azure/' README.md`)
# are refused as well. Rewrite them without a literal path.
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

# sandbox.credentials.envVars `mode: "deny"` is the primary guard, but excludedCommands
# such as `gh *` run outside the sandbox, so the expansion is caught here as well.
if printf '%s' "$command" | grep -Eq '\$\{?(AZURE|SNOWFLAKE|SNOWSQL|GH|GITHUB)_'; then
  deny "Azure/Snowflake/GitHub の認証系環境変数の展開は禁止です（値が transcript に漏洩するため）。設定値は az / snowflake / gh CLI のサブコマンド経由で扱ってください。"
fi

# Quoting (`~/".azure"`), repeated slashes, `/./` and a leading `./` are all equivalent to
# the shell but distinct to a plain string match, so fold them before comparing.
normalized="$(printf '%s' "$command" | tr -d "\"'" | sed -E 's#/{2,}#/#g')"
# Overlaps such as `/././` need repeated passes, and BSD sed does not accept label branches
# (`:a; ...; ta`) in a one-liner, so the loop lives in the shell.
while printf '%s' "$normalized" | grep -q '/\./'; do
  normalized="$(printf '%s' "$normalized" | sed -E 's#/\./#/#g')"
done
normalized="$(printf '%s' "$normalized" | sed -E 's#(^|[[:space:]<>|;&=(])\./#\1#g')"

# A preceding alphanumeric or underscore excludes the match, so hostnames such as
# `management.azure.com` are not caught.
if printf '%s' "$normalized" | grep -Eq '(^|[^[:alnum:]_])(\.(azure|snowflake|snowsql)|\.config/(gh|snowflake))(/|[[:space:];|&<>)]|$)'; then
  deny_path
fi

exit 0
