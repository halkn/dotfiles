---
description: このリポジトリの Claude Code 設定を監査・変更するときに使う。判断基準・手順・実測記録を持つ。対象は claude/settings.json・.claude/settings.json・claude/hooks/・claude/CLAUDE.md。sandbox の allowRead/denyRead や permissions の allow/deny/ask を見直す、hook を足す・消す、excludedCommands を増やす、auto モードの挙動を確認する、worktree や subagent の runtime 上限を調べる、といった作業。
---

# Claude Code 設定の監査

## 判断基準

### 3 層の役割分担

どの層に書くかは何に耐えてほしいかで決める。取り違えると効かないガードが増える。

- **CLAUDE.md / skill**: context であって強制ではない。規約・判断基準を置く
- **`permissions` / hook**: コマンド文字列の解析なので、変数展開や余分な空白で外れる
- **`sandbox`**: OS が強制する唯一の境界だが、効くのは Bash 層だけ。Edit / Write は `permissions` の管轄

能力の制限（任意コード実行・ファイル読取）は sandbox に寄せ、`permissions` / hook は sandbox で表現できないもの（不可逆な外向き操作の確認）と二次防御に使う。書込を確実に止めたい対象は Bash 経路と tool 経路の両方を塞ぐ。

### ガードを足す・消すとき

- 標準機能（sandbox・`permissions`・auto モードの classifier）で代替できないことを先に示す。既定の classifier ルールは `claude auto-mode defaults` で読める
- 防御は「道具」ではなく「参照される資産」側を列挙する。インタプリタ名・読取コマンド名の列挙は回避手段が開いている（実測は [sandbox-permissions.md](references/sandbox-permissions.md)）
- deny に置くのは「取り返しがつかない」かつ「正当な用途がほぼ無い」ものだけ。破壊的だが正当な用途もある操作（`git push --force`・`mise bootstrap --force-dotfiles` 等）は ask に置く。deny は代替手段を塞ぐだけだが、ask なら auto モード中も classifier より前に確認が入る
- `claude auto-mode defaults` が名指ししている操作（`git reset --hard`・`git remote set-url`・cron 登録等）は permissions に重複させない。classifier はユーザーが明示的に指示した場合だけ通すので、同じ形を ask に置くと指示済みの操作にも確認が出る。名指しされていない形（`git checkout -f`・`git branch -D`・`git worktree remove`）だけを ask に残す
- Claude Code の自己保護はロード元のパスとその symlink 先にしか届かない。repo 側に実体を持ち Claude Code が実行するファイル（`claude/hooks/*.sh` 等）は `sandbox.filesystem.denyWrite` に実体パスで明示する
- sandbox が既に決定論的に制御しているもの（書込先は write allowlist、送信先は network allowlist）と、git で戻せる変更（lockfile・依存）は deny に置かない。ask は allow より先に評価されるので、ask のパターンを広げると read-only 形まで毎回プロンプトになる
- 指示・ツール・公開先はローカルで版管理しているものだけに絞る。claude.ai 由来の skill / connector と Artifact の公開は設定キーで閉じる（`syncClaudeAiSkills` / `disableClaudeAiConnectors` / `enableArtifact`）

### 置き場所

- そのコマンドを複数のリポジトリで打つかで決める。単一リポジトリでしか実行しないもの（`mise bootstrap` / `mise run setup|sync|update`）は `.claude/settings.json`、汎用のもの（`mise tasks` 等）は `claude/settings.json`。sandbox の allowRead / allowWrite も同じ基準で分ける。project settings から読まれないのは `defaultMode` と `autoMode` だけで、`permissions` の allow / deny / ask は読まれる
- `claude/settings.json` は public repo にコミットされるため `autoMode.environment` に社内・仕事用のインフラ情報（組織名・内部ホスト名等）を書かない。仕事用の trusted infrastructure は `/Library/Application Support/ClaudeCode/managed-settings.json`（repo 外・追跡外）に記述する
- `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙。シークレット系 CLI ツールを導入したら環境変数名を追加する

## 手順

1. 変更対象キーの現状値を `claude/settings.json` と `.claude/settings.json` で確認する。このリポジトリは既に設定済みの範囲が広く、現状を見ずに書くと重複や矛盾した提案になる
1. 下の「再提案しない」と references の該当箇所を読む
1. hook や permissions を触るなら `claude auto-mode defaults` で既定の classifier ルールを読む。実行可否は `which` で判定せず直接叩いて確かめる（PATH に出なくても実行できることがある）。実際に失敗したときだけ references の記録で代替し、応答に「既定ルールは未確認」と明示する
1. 変更後は新規セッションで、意図した allow / deny が効いていることを実際のコマンドで確かめる
1. `mise run lint` を通す。read を狭める変更はツールが黙って既定値で動くだけのことがあり、壊れたことが結果の変化としてしか出ない

## 根拠の取り方

- 設定キー・フラグ・既定値を名指しする文は公式 docs（code.claude.com/docs）と CHANGELOG を根拠にする。`$schema` が指す schemastore 定義は追従が遅く（`sandbox`・`fileSuggestion` 等が未収録）、キーの有効性判断には使わない
- references の記録には測定時の版（と sandbox はプラットフォーム）を添えてある。**現行と一致する限りそのまま従い、一致しなければ docs か再測定で裏を取る。** 対象は Claude Code だけでなく記録に出てくるツール全て（mise・gh・hunk・herdr・Neovim・emmylua_check）。`claude --version` / `<tool> --version` で突き合わせる
- 裏を取れた記録は版のスタンプを現行へ更新する。測り直せなかったものは古い版のまま残し、その旨を記述に残す
- 認証情報と sandbox 境界に関わる記述は、版が一致していても手順 4 で実際に効いていることを確かめる
- sandbox の実測は macOS（Seatbelt）と WSL2（bubblewrap）で別に取る。実装が違うので片方の結果を他方へ一般化しない。バージョンだけ書かれてプラットフォームが書かれていない記述は macOS のものとして扱う
- sandbox の挙動を測るときは `~/.claude/settings.json` を書き換えず、`claude --settings <file> -p` の使い捨てセッションで測る。ただし配列はスコープ間でマージされるので、この方法で **allow を狭めることはできない**（deny の追加だけができる）。`CLAUDE_CONFIG_DIR` を差し替える方法は OAuth を引けず（`Not logged in`）使えない
- サンドボックス内から起動した `claude` は keychain を読めないので、probe セッションは Claude Code の外側のターミナルから実行する
- `sandbox` を変更したら**新規セッション**で効果を確認する。作業中のセッションは変更前のポリシーで動き続けることがあるので、そこでの結果を根拠にしない

## 再提案しない

検討して採用しなかった設定。結論だけ置く（経緯は各 commit にある）。

- `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`: Bash tool が広範に壊れる
- `~/.cache` を丸ごと allow して例外を `denyWrite` で列挙する形: fail-open になる
- `sandbox.network.tlsTerminate` と `credentials.envVars` の `mode: "mask"`
- `az *` の `excludedCommands` 除外: `strictAllowlist` を迂回する egress 経路になる
- `gh *` の除外を外すこと: sandbox 内の `gh` は keyring と TLS の 2 系統で壊れる（維持する）
- `Bash(git push --force*)` の deny: `--force-with-lease` まで塞ぐ。ask で足りる
- `.worktreeinclude`: gitignored file を agent の checkout へ複製すると露出面が広がる
- subagent の同時実行数・nesting 深さを `env` で下げること: 抑えたいのは委譲の判断の質であって同時実行数ではない

## References

手順 2 でどれを開くかは、扱う対象で決める。

- [sandbox-permissions.md](references/sandbox-permissions.md): allowRead / denyRead / credentials を足す・削る、deny が効かない、`excludedCommands` を増やす、`permissions` のパターンが意図通り当たらない、auto モードで allow が無視される
- [hooks.md](references/hooks.md): hook を足す・消す・書き換える、hook が黙って発火しない、`credentials.envVars` を追加する
- [worktree-subagent.md](references/worktree-subagent.md): `isolation: worktree` の subagent に何を任せるか、`git worktree add` を打つ、`.claude/worktrees/` の掃除、subagent の同時実行数・nesting の上限
