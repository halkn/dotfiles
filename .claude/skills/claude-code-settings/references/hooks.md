# PreToolUse hook

hook を足す・消すときは、標準機能（sandbox・`permissions`・auto モードの classifier）で代替できないことを先に示す。現行 3 本それぞれの根拠は `claude/hooks/*.sh` の冒頭コメントにある。

classifier の既定 allow ルール `Git Push Destination` は「セッションの repo なら default branch への push も通常操作」と明示しているので、main/master は classifier では止まらない（v2.1.226 で確認）。`permissions.ask` の `Bash(git push * main*)` が素直な形を、`block-main-push.sh` が refspec 形を捕捉する 2 層で担保していて、`autoMode` 側に重複ルールは置いていない。

## 実装上の制約（実測済み）

- **hook の判定基準は「参照される資産」側に置く**: 認証情報のパス・環境変数名・push 先ブランチ・PR 先 owner は閉じた集合なので、そちらを列挙してコマンド文字列全体に照合する。現行 hook は全てこの形。ただし対象が閉じていても綴り方は閉じていないので、パスを照合する前にクォート・重複スラッシュ・`/./`・先頭 `./` を正規化する。それでもパスを分割する形（`cd <dir> && cat <rest>`）や変数経由は通るため、hook は sandbox に残った穴の二次防御と位置づけ、単独の境界にしない
- 逆に「道具の列挙」（インタプリタ名・読取コマンド名）で hook を書かない。回避手段が開いている。理由は [sandbox-permissions.md](sandbox-permissions.md) を参照
- PreToolUse hook に `if` フィルタ（permission rule 構文）を使わない: prefix マッチのため `git push && gh pr create ...` のような複合コマンドで hook 自体がスキップされ、スクリプト側のセグメント解析による防御が無効化される
- hook の停止は `exit 2` で書く。docs 上、exit 2 は permission rule の評価より前に tool call を止めるので allow ルールにも勝つ。JSON の `permissionDecision` は permission rule を飛び越えられない（`"allow"` を返しても deny / ask ルールは評価される）。逆に確認を出したいだけなら JSON の `"ask"` を使う。これは auto モードの classifier を迂回してプロンプトを出す唯一の hook 手段。exit 1 は non-blocking なので停止に使わない
- PreToolUse hook の `command` にスクリプトパスを直接書かない: スクリプト不在時は exit 127 の non-blocking error になりガードが無言で失効する。`h=<path>; [ -x "$h" ] || { echo ... >&2; exit 2; }; exec "$h"` の形で包み、欠落を exit 2 でブロックさせる。`claude/hooks/` に追加したスクリプトは `mise bootstrap` を実行するまで `~/.claude/hooks/` に symlink されないため、この失効は容易に起きる

## credentials.envVars との分担

- `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙リスト。`mode: "deny"` はサンドボックス内のコマンドから当該変数を消す（ダミー変数で動作を確認済み・v2.1.226）が、`excludedCommands` は sandbox 外で走るため適用されない。そちらは `claude/hooks/block-secret-read.sh` の環境変数展開チェックが受け持つ
