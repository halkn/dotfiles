---
paths:
  - "claude/**"
  - ".claude/**"
---

# Claude Code 設定の変更ルール

## 根拠の取り方

- `claude/settings.json` の監査・変更は公式 docs（code.claude.com/docs）と CHANGELOG を根拠にする。`$schema` が指す schemastore 定義は追従が遅く（`sandbox`・`fileSuggestion` 等が未収録）、キーの有効性判断には使わない

## 採用しない設定（実測済み）

- `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` は**設定しない**: Anthropic・クラウドプロバイダ系の認証情報を全サブプロセスから strip する機能だが、この環境では有効化すると Bash tool が広範に機能不全を起こし、`permissions.defaultMode: "auto"` も正しく反映されなかった（2026-07 実機確認・v2.1.220）。再度有効化を検討する場合は、まず狭いスコープで再現するか確認すること
- `sandbox.credentials.files` / `filesystem.denyRead` による `~/.config/gh` の deny は**採用しない**: read 側は `allowRead` が denied region 内を再許可する仕様のため、`allowRead: ~/.config` の内側では deny が実効しない（v2.1.207 で実測確認済み）。gh token の読取防止は `claude/hooks/block-secret-read.sh` が担う
- PreToolUse hook に `if` フィルタ（permission rule 構文）を使わない: prefix マッチのため `git push && gh pr create ...` のような複合コマンドで hook 自体がスキップされ、スクリプト側のセグメント解析による防御が無効化される
- `sandbox.network.tlsTerminate` + `sandbox.credentials.envVars` の `mode: "mask"` は**採用しない**: mask は sandbox proxy が sentinel を実値へ差し替える仕組みなので、`excludedCommands` でサンドボックス外を走る `gh` には適用されない。対象も環境変数に限られ、この環境の gh token は keychain / `~/.config/gh` 側にある。加えて `tlsTerminate` は experimental かつ全サンドボックスコマンドの TLS を終端するため、Go/Rust 製ツールの TLS 検証失敗リスクを広げる。`GH_TOKEN` / `GITHUB_TOKEN` は `deny` のまま据え置く

## sandbox.excludedCommands の方針

- `gh *` の除外は**維持する**。docs の Troubleshooting が Seatbelt 下の Go 製 CLI（`gh`・`gcloud`・`terraform`）の TLS 検証失敗に対して `excludedCommands` を明示的に推奨している。監査のたびに再検討しない
- `git` はネットワーク／認証を要するサブコマンド（`push`・`fetch`・`pull`・`clone`・`ls-remote`・`remote update|prune`・`submodule`）だけを除外する。`git *` 全体を除外すると `filesystem.denyRead: ["~/"]` が git 経由で素通しになる（`git hash-object ~/.ssh/id_ed25519` 等）。docs は linked worktree の共有 `.git` への書き込みを明示的に許可しており、ローカル操作はサンドボックス内で動く前提
- push は `.config/git/config` の `pushInsteadOf` により SSH。HTTPS 化しても credential helper が Seatbelt 下で通らず、`allowUnsandboxedCommands: false` のため即ハードエラーになるので、ネットワーク系 git は除外に残す
- 引数なし形（`git push` 等）とワイルドカード形を併記する。除外に追加する前に、そのサブコマンドがサンドボックス内で実際に失敗することを確認する

## 手動での追記が必要な設定

- `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙リスト。新しいシークレット系 CLI ツールを導入したら対応する環境変数名をここに追加する
- `claude/settings.json` は public repo にコミットされるため `autoMode.environment` に社内・仕事用のインフラ情報（組織名・内部ホスト名等）を書かない。仕事用の trusted infrastructure は `/Library/Application Support/ClaudeCode/managed-settings.json`（repo 外・追跡外）に記述する

## Auto モードの前提

`permissions.defaultMode` は `auto`。permission prompt の代わりに classifier（分類モデル）が各アクションを評価する。

- `autoMode`（および `permissions.defaultMode: "auto"`）は user settings（`~/.claude/settings.json`）・managed settings・`--settings` フラグからのみ読まれる仕様で、`.claude/settings.json` / `.claude/settings.local.json` からは読まれない（v2.1.207 以降。repo や build step が自分に auto モードや trusted infrastructure を付与できないようにするため）
- `autoMode.classifyAllShell: true` により、auto モード中は `permissions.allow` の Bash ルール（`Bash(git *)` 等）が全て停止し、全シェルコマンドが classifier 経由になる。allow リストは `acceptEdits` 等の他モードへ切り替えたときの fallback として残している
- `classifyAllShell` が停止するのは allow ルールだけで、`permissions.ask` は auto モードでも classifier より前に評価され必ずプロンプトを出す。docs も push / PR に人間のチェックポイントを置く推奨手段として `permissions.ask` を挙げている。よって `permissions.ask` は他モード用の fallback ではなく auto モードでの一次ガード
- main/master への直接 push は auto モードの既定では許可される（v2.1.211 以降、作業中リポジトリへの push は原則無確認）。このリポジトリでは 2 層で担保する: `permissions.ask` の `Bash(git push * main*)` 等が素直な形を捕捉し、`git push origin HEAD:main` のように `main` の前に空白が無く pattern がマッチしない refspec 形式は `claude/hooks/block-main-push.sh` が解釈して `ask` する。`autoMode` 側には重複ルールを置いていない
