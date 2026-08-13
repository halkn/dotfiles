---
paths:
  - "claude/**"
  - ".claude/**"
---

# Claude Code 設定の変更ルール

## 3 層の役割分担

どの層に書くかは、何に耐えてほしいかで決める。これを取り違えると、効かないガードを増やすことになる。

- **CLAUDE.md / `.claude/rules/`**: context であって強制ではない。守ってほしい規約・判断基準を置く
- **`permissions` / hook**: クライアントがコマンド文字列を見て判断する。文字列解析なので、変数展開や余分な空白で外れる。「モデルが従わなくても止まる」層だが、確実ではない
- **`sandbox`**: OS が実行中プロセスに強制する。文字列解析に依存しない唯一の境界で、prompt injection がモデルの判断を回避しても効く

よって、任意コード実行やファイル読取のような能力の制限は sandbox に寄せる。`permissions` / hook は sandbox で表現できないもの（不可逆な外向き操作の確認）と、sandbox に残った穴の二次防御に使う。

## ガードを足す・消すとき

- 標準機能（sandbox・`permissions`・auto モードの classifier）で代替できないことを先に示す。既定の classifier ルールは `claude auto-mode defaults` で読める
- 防御は「道具」ではなく「参照される資産」側を列挙する。インタプリタ名・読取コマンド名の列挙は回避手段が開いており、防御にならない
- deny に置くのは「取り返しがつかない」かつ「正当な用途がほぼ無い」ものだけ。破壊的だが正当な用途もある操作（`git reset --hard`・`mise bootstrap --force-dotfiles` 等）は ask に置く。deny は代替手段を塞ぐだけだが、ask なら auto モード中も classifier より前に確認が入る
- sandbox が既に決定論的に制御しているもの（書込先は write allowlist、送信先は network allowlist）と、git で戻せる変更（lockfile・依存）は deny に置かない
- ask は allow より先に評価されるので、ask のパターンを広げると read-only 形まで毎回プロンプトになる

## 置き場所

- そのコマンドを複数のリポジトリで打つかで決める。単一リポジトリでしか実行しないもの（`mise bootstrap` / `mise run setup|sync|update`）は `.claude/settings.json`、汎用のもの（`mise tasks` 等）は `claude/settings.json`。sandbox の allowRead / allowWrite も同じ基準で分ける
- `permissions` の allow / deny / ask は project settings からも読まれる。読まれないのは `defaultMode` と `autoMode`
- `claude/settings.json` は public repo にコミットされるため `autoMode.environment` に社内・仕事用のインフラ情報（組織名・内部ホスト名等）を書かない。仕事用の trusted infrastructure は `/Library/Application Support/ClaudeCode/managed-settings.json`（repo 外・追跡外）に記述する
- `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙。シークレット系 CLI ツールを導入したら対応する環境変数名を追加する

監査の手順・実測記録・現行 hook の存在理由は `/claude-code-settings` skill にある。設定を変える前に読む。
