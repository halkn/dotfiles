---
paths:
  - "claude/**"
  - ".claude/**"
---

# Claude Code 設定の変更ルール

設定キー・既定値・classifier の挙動はバージョンで変わる。ここに置くのは変わらない判断基準だけで、現在仕様は `/claude-code-settings` skill の手順で取得する。設定を変える前にその skill を読む。

## 3 層の役割分担

どの層に書くかは何に耐えてほしいかで決める。取り違えると効かないガードが増える。

- **CLAUDE.md / `.claude/rules/`**: context であって強制ではない。規約・判断基準を置く
- **`permissions` / hook**: コマンド文字列の解析なので、変数展開や余分な空白で外れる
- **`sandbox`**: OS が強制する唯一の境界だが、効くのは Bash 層だけ。Edit / Write は `permissions` の管轄

能力の制限（任意コード実行・ファイル読取）は sandbox に寄せ、`permissions` / hook は sandbox で表現できないもの（不可逆な外向き操作の確認）と二次防御に使う。書込を確実に止めたい対象は Bash 経路と tool 経路の両方を塞ぐ。

## ガードを足す・消すとき

- 標準機能（sandbox・`permissions`・auto モードの classifier）で代替できないことを先に示す
- 防御は「道具」ではなく「参照される資産」側を列挙する。インタプリタ名・読取コマンド名の列挙は回避手段が開いている
- deny に置くのは「取り返しがつかない」かつ「正当な用途がほぼ無い」ものだけ。破壊的だが正当な用途もある操作は ask に置く。deny は代替手段を塞ぐだけだが、ask なら auto モード中も classifier より前に確認が入る
- classifier が既に名指ししている操作を permissions に重複させない。classifier はユーザーが明示的に指示した場合だけ通すので、同じ形を ask に置くと指示済みの操作にも確認が出る
- Claude Code の自己保護が届くのは、それ自身がロードするパスと、そこから張られた symlink の先だけ。repo 側に実体を持ち Claude Code が実行するファイルは対象外なので、書込を明示的に塞ぐ
- sandbox が既に決定論的に制御しているもの（書込先・送信先）と、git で戻せる変更（lockfile・依存）は deny に置かない
- ask は allow より先に評価される。ask のパターンを広げると read-only 形まで毎回プロンプトになる
- 指示・ツール・公開先は、ローカルで版管理しているものだけに絞る

## 置き場所

- そのコマンドを複数のリポジトリで打つかで決める。単一リポジトリでしか実行しないものは `.claude/settings.json`、汎用のものは `claude/settings.json`。sandbox の allow も同じ基準で分ける。ただし project settings から読まれないキーがあるので、置く前に現在の仕様を確認する
- `claude/settings.json` は public repo にコミットされる。社内・仕事用のインフラ情報（組織名・内部ホスト名等）を書かない。仕事用の trusted infrastructure は repo 外の managed settings に置く
- 認証情報を持つファイル・環境変数の宣言は自動で広がらない前提で扱う。シークレットを扱う CLI を導入したら手で追加する
