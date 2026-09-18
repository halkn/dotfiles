# PreToolUse hook

判断基準は `SKILL.md`。ここに置くのは現行 hook の実装上の制約。個々の hook の根拠は `claude/hooks/*.sh` の冒頭コメントにある。

## docs を引く

- hook の exit code と JSON 出力の意味（どれが permission rule より先に効くか）: hooks のページ。停止は `exit 2`、確認を出したいだけなら JSON の `"ask"` を使う、という現行の使い分けはここに依存している

## 実装上の制約（実測済み）

- classifier の既定 allow ルール `Git Push Destination` は「セッションの repo なら default branch への push も通常操作」と明示しているので、main/master は classifier では止まらない（v2.1.226 で確認）。`permissions.ask` の `Bash(git push * main*)` が素直な形を、`block-main-push.sh` が refspec 形を捕捉する 2 層で担保していて、`autoMode` 側に重複ルールは置いていない
- **hook の判定基準は「参照される資産」側に置く**: 認証情報のパス・環境変数名・push 先ブランチ・PR 先 owner は閉じた集合なので、そちらを列挙してコマンド文字列全体に照合する。現行 hook は全てこの形。ただし対象が閉じていても綴り方は閉じていないので、パスを照合する前にクォート・重複スラッシュ・`/./`・先頭 `./` を正規化する。それでもパスを分割する形（`cd <dir> && cat <rest>`）や変数経由は通るため、hook は sandbox に残った穴の二次防御と位置づけ、単独の境界にしない
- PreToolUse hook に `if` フィルタ（permission rule 構文）を使わない: prefix マッチのため `git push && gh pr create ...` のような複合コマンドで hook 自体がスキップされ、スクリプト側のセグメント解析による防御が無効化される
- PreToolUse hook の `command` にスクリプトパスを直接書かない: スクリプト不在時は exit 127 の non-blocking error になりガードが無言で失効する。`h=<path>; [ -x "$h" ] || { echo ... >&2; exit 2; }; exec "$h"` の形で包み、欠落を exit 2 でブロックさせる。`claude/hooks/` に追加したスクリプトは `mise bootstrap` を実行するまで `~/.claude/hooks/` に symlink されないため、この失効は容易に起きる
- `watch` / `setsid` / `flock` などの exec wrapper と `find -exec|-delete` は prefix ルールで自動承認されない。hook 側でもこれらを読み飛ばして実行対象まで進める（オペランドを取る `timeout N` / `flock FILE` は単純な読み飛ばしでは解決できないので、hook は捕捉できない前提で扱う）

## credentials.envVars との分担

- `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙リスト。`mode: "deny"` はサンドボックス内のコマンドから当該変数を消す（ダミー変数で動作を確認済み・v2.1.226）が、`excludedCommands` は sandbox 外で走るため適用されない。そちらは `claude/hooks/block-secret-read.sh` の環境変数展開チェックが受け持つ
