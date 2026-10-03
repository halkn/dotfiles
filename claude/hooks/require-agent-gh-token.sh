#!/usr/bin/env bash
# PreToolUse(Bash): refuse GitHub-bound gh / git calls unless Claude Code's own token is in place.
#
# Claude Code authenticates to GitHub with a fine-grained token kept in $GH_CONFIG_DIR/hosts.yml
# (GH_CONFIG_DIR is set in claude/settings.json), so a session can do less than the person's own
# gh login. gh looks for a token in GH_TOKEN / GITHUB_TOKEN, then hosts.yml, then the
# macOS keychain, and the keychain entry is shared by every config directory: with the token
# missing, gh and git's `gh auth git-credential` helper fall back to the person's token without a
# word. This hook turns that fallback into a refusal. It reads the token's prefix, never prints it.
#
# git is checked only when it talks to github.com, so pushes to Azure DevOps and other hosts do
# not need the GitHub token.
set -euo pipefail

command="$(jq -r '.tool_input.command // ""')"

s='[[:space:]]+'
lead="^[[:space:]]*(cd${s}[^[:space:]]+[[:space:]]*&&[[:space:]]*)?"
gh_call="${lead}gh${s}"
git_call="${lead}git${s}(push|fetch|clone|ls-remote|remote${s}(update|prune))([[:space:]]|$)"

needs_token=0
if [[ "$command" =~ $gh_call ]]; then
  needs_token=1
elif [[ "$command" =~ $git_call ]]; then
  # Captured rather than piped to `grep -q`, which under pipefail can read a match as a failure.
  remotes="$(git config --get-regexp '^remote\..*\.(push)?url$' 2>/dev/null || true)"
  if [[ "$command" == *github.com* ]] || [[ "$remotes" == *github.com* ]]; then
    needs_token=1
  fi
fi
[ "$needs_token" -eq 1 ] || exit 0

if [ -z "${GH_TOKEN:-}" ] && [ -z "${GITHUB_TOKEN:-}" ] && [ -n "${GH_CONFIG_DIR:-}" ] &&
  grep -Eq '^[[:space:]]*oauth_token:[[:space:]]*github_pat_' "$GH_CONFIG_DIR/hosts.yml" 2>/dev/null; then
  exit 0
fi

cat >&2 <<'MSG'
Claude Code 用の GitHub トークンが使える状態にないため、GitHub への gh / git の実行を止めました。

gh は、Claude Code 用のトークン（GH_CONFIG_DIR の hosts.yml にある fine-grained トークン）が無いと、
keychain にある人の全権限トークンに黙って切り替わります。次のどれかに当たっています。

- GH_CONFIG_DIR が設定されていない（claude/settings.json の env）
- GH_CONFIG_DIR/hosts.yml に github_pat_ で始まる oauth_token が無い
- GH_TOKEN / GITHUB_TOKEN が環境変数に設定されている（hosts.yml より優先される）

セットアップはリポジトリの README（Claude Code の GitHub トークン）にあります。ユーザーに伝えて、
回避策は探さないでください。
MSG
exit 2
