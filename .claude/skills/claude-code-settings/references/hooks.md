# PreToolUse hook

## 3 本を残す理由

hook を足す・消すときは、標準機能（sandbox・`permissions`・auto モードの classifier）で代替できないことを先に示す。現行 3 本の根拠は以下（v2.1.226・macOS で確認）。

- `block-secret-read.sh`: `az` は sandbox 内で動くため `~/.azure` は allowRead に置くしかなく、sandbox では閉じられない。加えて `excludedCommands` の `gh` / ネットワーク系 git は sandbox 外で走るので `credentials.envVars` の deny も効かない。この 2 点が hook の担当範囲で、`~/.config/gh` のように sandbox で閉じられるものについては二次防御
- `block-main-push.sh`: auto モードの既定 allow ルール `Git Push Destination` が「セッションの repo なら default branch への push も通常操作」と明示しているため、classifier は main/master を止めない。`permissions.ask` のパターンは `main` の前に空白を要求するので refspec 形（`HEAD:main`）を捕捉できない
- `scope-gh-pr-create.sh`: classifier の `Create Public Surface` が扱うのは「別の repo / org を狙う PR」で、セッション中の repo の owner が信頼範囲かどうかは判定しない。owner は決定論的に判定できるので hook に置く

main/master への直接 push は auto モードの既定では許可される（allow ルール `Git Push Destination`: 「Pushing to any branch of the session's repo is ordinary — the default branch included」。v2.1.226 で確認）。このリポジトリでは 2 層で担保する: `permissions.ask` の `Bash(git push * main*)` 等が素直な形を捕捉し、`git push origin HEAD:main` のように `main` の前に空白が無く pattern がマッチしない refspec 形式は `claude/hooks/block-main-push.sh` が解釈して `ask` する。`autoMode` 側には重複ルールを置いていない。

## 実装上の制約（実測済み）

- **hook の判定基準は「参照される資産」側に置く**: 認証情報のパス・環境変数名・push 先ブランチ・PR 先 owner は閉じた集合なので、そちらを列挙してコマンド文字列全体に照合する。現行 hook は全てこの形。ただし対象が閉じていても綴り方は閉じていないので、パスを照合する前にクォート・重複スラッシュ・`/./`・先頭 `./` を正規化する。それでもパスを分割する形（`cd <dir> && cat <rest>`）や変数経由は通るため、hook は sandbox に残った穴の二次防御と位置づけ、単独の境界にしない
- 逆に「道具の列挙」（インタプリタ名・読取コマンド名）で hook を書かない。回避手段が開いている。理由は [sandbox-permissions.md](sandbox-permissions.md) を参照
- PreToolUse hook に `if` フィルタ（permission rule 構文）を使わない: prefix マッチのため `git push && gh pr create ...` のような複合コマンドで hook 自体がスキップされ、スクリプト側のセグメント解析による防御が無効化される
- hook の停止は `exit 2` で書く。docs 上、exit 2 は permission rule の評価より前に tool call を止めるので allow ルールにも勝つ。JSON の `permissionDecision` は permission rule を飛び越えられない（`"allow"` を返しても deny / ask ルールは評価される）。逆に確認を出したいだけなら JSON の `"ask"` を使う。これは auto モードの classifier を迂回してプロンプトを出す唯一の hook 手段。exit 1 は non-blocking なので停止に使わない
- PreToolUse hook の `command` にスクリプトパスを直接書かない: スクリプト不在時は exit 127 の non-blocking error になりガードが無言で失効する。`h=<path>; [ -x "$h" ] || { echo ... >&2; exit 2; }; exec "$h"` の形で包み、欠落を exit 2 でブロックさせる。`claude/hooks/` に追加したスクリプトは `mise bootstrap` を実行するまで `~/.claude/hooks/` に symlink されないため、この失効は容易に起きる

## credentials.envVars との分担

- `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙リスト。`mode: "deny"` はサンドボックス内のコマンドから当該変数を消す（ダミー変数で動作を確認済み・v2.1.226）が、`excludedCommands` は sandbox 外で走るため適用されない。そちらは `claude/hooks/block-secret-read.sh` の環境変数展開チェックが受け持つ
