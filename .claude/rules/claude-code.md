---
paths:
  - "claude/**"
  - ".claude/**"
---

# Claude Code 設定の変更ルール

## 根拠の取り方

- `claude/settings.json` の監査・変更は公式 docs（code.claude.com/docs）と CHANGELOG を根拠にする。`$schema` が指す schemastore 定義は追従が遅く（`sandbox`・`fileSuggestion` 等が未収録）、キーの有効性判断には使わない
- このファイルの「実測済み」記述にはバージョンを添える。docs 側の仕様が後から変わることがあるので、記述したバージョンと現行バージョンが離れていたら、docs と再測定で裏を取り直してから従う

## 3 層の役割分担

どの層に書くかは、何に耐えてほしいかで決める。これを取り違えると、効かないガードを増やすことになる。

- **CLAUDE.md / `.claude/rules/`**: context であって強制ではない。docs も「Claude treats them as context, not enforced configuration」と書いている。守ってほしい規約・判断基準を置く
- **`permissions` / hook**: クライアントがコマンド文字列を見て判断する。文字列解析なので、docs 自身が読み取り専用判定について変数展開（`URL=... && curl $URL`）や余分な空白で外れる例を挙げている。「モデルが従わなくても止まる」層だが、確実ではない
- **`sandbox`**: OS が実行中プロセスに強制する。docs は「holds regardless of what the model chose to run and even if an allowed command does more than its name suggests」「prompt injection が Claude の判断を回避しても効く」と位置づけている。ここが唯一、文字列解析に依存しない境界

よって、任意コード実行やファイル読取のような能力の制限は sandbox に寄せる。`permissions` / hook は sandbox で表現できないもの（不可逆な外向き操作の確認）と、sandbox に残った穴の二次防御に使う。

## 採用しない設定（実測済み）

- **「道具の列挙」で防御を書かない**: インタプリタ名（`python` 等）や読取コマンド名（`cat` 等）を deny / hook で列挙しても、`perl -e`・`node -e`・`bash -c`・`tr < f`・`while read` リダイレクト・一旦ファイルに書いてから実行、で回避できる（実測済み）。道具の集合は開いている。Bash tool を与える以上、任意コード実行は前提であり、境界は sandbox（`filesystem` の allow/deny・`network.strictAllowlist`・`allowUnsandboxedCommands: false`）と auto モードの classifier が持つ。道具の選好（`python` より `jaq` / `ryl`）は防御ではなくスタイルなので `claude/CLAUDE.md` 側に置く
- **hook の判定基準は「参照される資産」側に置く**: 認証情報のパス・環境変数名・push 先ブランチ・PR 先 owner は閉じた集合なので、そちらを列挙してコマンド文字列全体に照合する。現行 hook は全てこの形。ただし対象が閉じていても綴り方は閉じていないので、パスを照合する前にクォート・重複スラッシュ・`/./`・先頭 `./` を正規化する。それでもパスを分割する形（`cd <dir> && cat <rest>`）や変数経由は通るため、hook は sandbox に残った穴の二次防御と位置づけ、単独の境界にしない
- `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` は**設定しない**: Anthropic・クラウドプロバイダ系の認証情報を全サブプロセスから strip する機能だが、この環境では有効化すると Bash tool が広範に機能不全を起こし、`permissions.defaultMode: "auto"` も正しく反映されなかった（2026-07 実機確認・v2.1.220）。再度有効化を検討する場合は、まず狭いスコープで再現するか確認すること
- `allowRead` の内側に `denyRead` を置いて穴を塞ごうとしない: **効かない**。docs は「read 規則はより具体的なパスが勝つ」「an exact deny holds inside a wider allow」と書いているが、macOS/Seatbelt では `allowRead: ~/.config` + `denyRead: ~/.config/gh` の状態で `~/.config/gh/hosts.yml` が読めた（v2.1.207 と v2.1.223 で実測、sandbox 自体は同時に `~/.ssh` 等を拒否しており有効）。しかも `filesystem.denyRead` は `credentials.files` の deny と違って無効時の `error` 通知が無いので、書いても無言で失効する。**read を塞ぐ唯一の手段は `allowRead` にそのパスを含めないこと**
- `~/.config` は allowRead に**サブディレクトリ単位で書けない**。`~/.config` を外して `~/.config/mise` 等を列挙すると、列挙したパスまで含めて `~/.config` 配下が全て読めなくなる（v2.1.223・macOS で再起動後も再現）。`~/.cache/mise`・`~/.local/bin`・`~/.claude/skills` のように他の親配下では同じ書き方が効くので、`~/.config` 固有の挙動。よってここは「丸ごと開ける / 丸ごと閉じる」の二択になり、`~/.config/gh`・`~/.config/snowflake` だけを閉じることはできない。現在は開ける側を選んでいる（閉じると rumdl がユーザー設定を読めず MD013 を既定の 80 文字で適用して誤検知を出し、`rg` も `RIPGREP_CONFIG_PATH` の読取に失敗する）。この 2 つは `claude/hooks/block-secret-read.sh` が唯一のガード
- `allowRead` を削ったら `mise run lint` を通す。ツールが自分の設定を読めなくなっても多くは失敗せず、黙って既定値で動く。壊れたことが**結果の変化**としてしか出ないので、read を狭める変更は必ず lint で確認する
- sandbox から除外したコマンド（`excludedCommands`）には filesystem 制限が一切効かない。`gh` は除外しているので、仮に `~/.config/gh` を閉じられたとしても `gh` 自身の認証は壊れない。逆に `az` は sandbox 内で動くため `~/.azure` は allowRead が必要で、こちらは hook でしか守れない
- PreToolUse hook に `if` フィルタ（permission rule 構文）を使わない: prefix マッチのため `git push && gh pr create ...` のような複合コマンドで hook 自体がスキップされ、スクリプト側のセグメント解析による防御が無効化される
- hook の停止は `exit 2` で書く。docs 上、exit 2 は permission rule の評価より前に tool call を止めるので allow ルールにも勝つ。JSON の `permissionDecision` は permission rule を飛び越えられない（`"allow"` を返しても deny / ask ルールは評価される）。逆に確認を出したいだけなら JSON の `"ask"` を使う。これは auto モードの classifier を迂回してプロンプトを出す唯一の hook 手段。exit 1 は non-blocking なので停止に使わない
- PreToolUse hook の `command` にスクリプトパスを直接書かない: スクリプト不在時は exit 127 の non-blocking error になりガードが無言で失効する。`h=<path>; [ -x "$h" ] || { echo ... >&2; exit 2; }; exec "$h"` の形で包み、欠落を exit 2 でブロックさせる。`claude/hooks/` に追加したスクリプトは `mise bootstrap` を実行するまで `~/.claude/hooks/` に symlink されないため、この失効は容易に起きる
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

- `autoMode`（および `permissions.defaultMode: "auto"`）は user settings（`~/.claude/settings.json`）・managed settings・`--settings` フラグからのみ読まれる仕様で、`.claude/settings.json` / `.claude/settings.local.json` からは読まれない（`permissions.defaultMode` は v2.1.207、`autoMode` ブロックは v2.1.219 以降。repo や build step が自分に auto モードや trusted infrastructure を付与できないようにするため）
- `autoMode.classifyAllShell: true` により、auto モード中は `permissions.allow` の Bash ルール（`Bash(git *)` 等）が全て停止し、全シェルコマンドが classifier 経由になる。allow リストは `acceptEdits` 等の他モードへ切り替えたときの fallback として残している
- `permissions.allow` は auto モードでは死んでいるので、判断基準は「他モードへフォールバックしたときに無確認で通っても安全か」だけ。サブコマンドを明示した read-only 形にとどめ、`Bash(git *)` のような動詞を跨ぐワイルドカードは置かない（`git -c core.pager=<cmd> log` や `gh alias set --shell` のように、`*` が空白を跨いで書き込み・任意実行サブコマンドを取り込む）
- 破壊的だが正当な用途もある操作（`git reset --hard` / `git clean -f` / `git worktree remove` / `uv self update` / `mise run update` 等）は deny ではなく `permissions.ask` に置く。deny は代替手段を塞ぐだけだが、ask なら auto モード中も classifier より前に確認が入る
- `permissions.deny` に残すのは「取り返しがつかない」かつ「正当な用途がほぼ無い」ものだけ。回避可能な道具の列挙と、sandbox が既に決定論的に制御しているもの（書込先は write allowlist、送信先は network allowlist）は deny に置かない。git で戻せる変更（lockfile・依存）も deny の対象にしない
- `sandbox.network.strictAllowlist` を exfiltration の防波堤として数えない。制御するのは送信先だけで中身ではなく、docs は `github.com` のような広いドメインの許可について「can create paths for data exfiltration」と明記し、proxy が TLS を検査せず client 提供のホスト名で判断するため domain fronting で allowlist 外へ到達しうるとまで書いている。allowlist 内にも remote code path（`codeload.github.com`）と exfiltration path（`api.github.com` の gist）が残る。ネットワーク系の deny を外すときは、残余リスクを負うのが classifier だと承知の上で外す。非 HTTP の生ソケット（`nc` / `ssh` / `scp`）は proxy の対象外になりうるので deny に残す
- 環境そのものを変える更新系（`mise run update|setup|sync`・`mise bootstrap*`）は git で戻せないので ask に置く
- ask / deny のパターンは、実際に打たれる形を `mise.toml` や `README.md` で確認してから書く。`mise bootstrap` のようにサブコマンド・フラグの形が一定しないものは、`*` 無しの完全一致では実際の呼び出しを 1 つも捕捉できない。prefix パターンでは例外（`--dry-run` 等の read-only 形）を表現できないので、そこまで ask に含めて安全側に倒す
- deny のパターンはオプションの等号形も併記する。`--http-method post` だけを書くと `--http-method=POST` がすり抜ける
- パターンの照合規則（docs 記載。ここを誤解すると書いたつもりのルールが効かない）:
  - `*` は空白を跨いで任意長にマッチする。`Bash(git * main)` は `git push origin main` にも `git merge main` にもマッチする
  - 末尾 `*` の直前に空白があると語境界を要求する。`Bash(ls *)` は `lsof` にマッチせず、`Bash(ls*)` はマッチする
  - 複合コマンドは `&&` `||` `;` `|` `|&` `&` と改行で分割され、各サブコマンドが独立に照合される。パイプで繋いでも deny は回避できない一方、allow は全サブコマンドが一致しないと成立しない
  - `watch` / `setsid` / `flock` などの exec wrapper と `find -exec|-delete` は prefix ルールで自動承認されない。hook 側でもこれらを読み飛ばして実行対象まで進める（オペランドを取る `timeout N` / `flock FILE` は単純な読み飛ばしでは解決できないので、hook は捕捉できない前提で扱う）
- `classifyAllShell` が停止するのは allow ルールだけで、`permissions.ask` は auto モードでも classifier より前に評価され必ずプロンプトを出す。docs も push / PR に人間のチェックポイントを置く推奨手段として `permissions.ask` を挙げている。よって `permissions.ask` は他モード用の fallback ではなく auto モードでの一次ガード
- main/master への直接 push は auto モードの既定では許可される（v2.1.211 以降、作業中リポジトリへの push は原則無確認）。このリポジトリでは 2 層で担保する: `permissions.ask` の `Bash(git push * main*)` 等が素直な形を捕捉し、`git push origin HEAD:main` のように `main` の前に空白が無く pattern がマッチしない refspec 形式は `claude/hooks/block-main-push.sh` が解釈して `ask` する。`autoMode` 側には重複ルールを置いていない
