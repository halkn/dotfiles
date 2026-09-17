---
description: このリポジトリの Claude Code 設定（claude/settings.json・.claude/settings.json・claude/hooks/・sandbox・permissions・PreToolUse hook・excludedCommands・native worktree・subagent）を監査・変更するときに、現在仕様を取得して裏を取る手順。rule や nested CLAUDE.md が読み込まれない・hook が発火しない理由を調べる、sandbox の allowRead/denyRead や permissions の allow/deny/ask を見直す、hook を足す・消す、auto モードの挙動を確認する、といった作業で使う。
---

# Claude Code 設定の監査

判断基準は `.claude/rules/claude-code.md`。ここに置くのは、**現在仕様を取得して確かめる手順**。設定キー・既定値・classifier の挙動はバージョンで変わるので、この skill 自身は upstream の仕様を持たない。

## 手順

1. 現状を読む。変更対象キーの現在値を `claude/settings.json` と `.claude/settings.json` の両方で確認する。設定済みの範囲が広く、現状を見ずに書くと重複や矛盾した提案になる
1. `claude --version` を取る。以降の記録・docs の読み方をこれに合わせる
1. 公式 docs（code.claude.com/docs）・`--help`・CHANGELOG で現在仕様を確認する。`$schema` が指す schemastore 定義は追従が遅く、キーの有効性判断には使わない
1. hook や permissions を触るなら `claude auto-mode defaults` で既定の classifier ルールを読む。実行可否は `which` で判定せず直接叩いて確かめる（PATH に出なくても実行できることがある）。実際に失敗したときだけ、応答に「既定ルールは未確認」と明示する
1. [local-findings.md](references/local-findings.md) を読む。このリポジトリの構成が原因で起きること、および**検討して採用しなかった設定**が記録してある。再提案する前に確認する
1. 変更する
1. **新規セッションで**、意図した allow / deny / hook が効いていることを実際のコマンドで確かめる。作業中のセッションは変更前のポリシーで動き続ける
1. `mise run lint` を通す。read を狭める変更はツールが黙って既定値で動くだけのことがあり、壊れたことが結果の変化としてしか出ない

## 挙動を測るときの注意

- `~/.claude/settings.json` を書き換えず、`claude --settings <file> -p` の使い捨てセッションで測る。ただし配列はスコープ間でマージされるので、この方法で **allow を狭めることはできない**（deny の追加だけができる）。`CLAUDE_CONFIG_DIR` を差し替える方法は OAuth を引けず使えない
- サンドボックス内から起動した `claude` は keychain を読めないので、probe セッションは Claude Code の外側のターミナルから実行する
- sandbox の実測は macOS（Seatbelt）と WSL2（bubblewrap）で別に取る。実装が違うので片方の結果を他方へ一般化しない
- 認証情報と sandbox 境界に関わる変更は、バージョン差が小さくても手順 7 で実際に効いていることを確かめる

## 記録する / しない

新しく分かったことを local-findings.md へ足すのは、**このリポジトリの構成（`~/.config` が symlink、ログインシェルが読むキャッシュ、repo 側に実体を持つ hook など）が原因**で、公式 docs からは辿り着けないときだけ。upstream の仕様・既定値・classifier のルール内容は、次に必要になったときに手順 3 と 4 で取り直す。
