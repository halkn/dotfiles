---
paths:
  - "claude/**"
  - ".claude/**"
---

# Claude Code 設定の変更ルール

## 根拠の取り方

- `claude/settings.json` の監査・変更は公式 docs（code.claude.com/docs）と CHANGELOG を根拠にする。`$schema` が指す schemastore 定義は追従が遅く（`sandbox`・`fileSuggestion` 等が未収録）、キーの有効性判断には使わない
- このファイルの「実測済み」記述にはバージョンを添える。docs 側の仕様が後から変わることがあるので、記述したバージョンと現行バージョンが離れていたら、docs と再測定で裏を取り直してから従う
- sandbox の実測は macOS（Seatbelt）と WSL2（bubblewrap）で別に取る。実装が違うので片方の結果を他方へ一般化しない。バージョンだけ書かれていてプラットフォームが書かれていない記述は macOS のものとして扱う
- sandbox の挙動を測るときは `~/.claude/settings.json` を書き換えず、`claude --settings <file> -p` の使い捨てセッションで測る。ただし配列はスコープ間でマージされるので、この方法で **allow を狭めることはできない**（deny の追加だけができる）。`CLAUDE_CONFIG_DIR` を差し替える方法は OAuth を引けず（`Not logged in`）使えない
- サンドボックス内から起動した `claude` は keychain を読めないので、probe セッションは Claude Code の外側のターミナルから実行する
- `sandbox` を変更したら**新規セッション**で効果を確認する。作業中のセッションは変更前のポリシーで動き続けることがあるので、そこでの結果を根拠にしない

## 3 層の役割分担

どの層に書くかは、何に耐えてほしいかで決める。これを取り違えると、効かないガードを増やすことになる。

- **CLAUDE.md / `.claude/rules/`**: context であって強制ではない。docs も「Claude treats them as context, not enforced configuration」と書いている。守ってほしい規約・判断基準を置く
- **`permissions` / hook**: クライアントがコマンド文字列を見て判断する。文字列解析なので、docs 自身が読み取り専用判定について変数展開（`URL=... && curl $URL`）や余分な空白で外れる例を挙げている。「モデルが従わなくても止まる」層だが、確実ではない
- **`sandbox`**: OS が実行中プロセスに強制する。docs は「holds regardless of what the model chose to run and even if an allowed command does more than its name suggests」「prompt injection が Claude の判断を回避しても効く」と位置づけている。ここが唯一、文字列解析に依存しない境界

よって、任意コード実行やファイル読取のような能力の制限は sandbox に寄せる。`permissions` / hook は sandbox で表現できないもの（不可逆な外向き操作の確認）と、sandbox に残った穴の二次防御に使う。

## PreToolUse hook を 3 本残す理由

hook を足す・消すときは、標準機能（sandbox・`permissions`・auto モードの classifier）で代替できないことを先に示す。現行 3 本の根拠は以下（v2.1.226・macOS で確認）。

- `block-secret-read.sh`: `az` は sandbox 内で動くため `~/.azure` は allowRead に置くしかなく、sandbox では閉じられない。加えて `excludedCommands` の `gh` / ネットワーク系 git は sandbox 外で走るので `credentials.envVars` の deny も効かない。この 2 点が hook の担当範囲で、`~/.config/gh` のように sandbox で閉じられるものについては二次防御
- `block-main-push.sh`: auto モードの既定 allow ルール `Git Push Destination` が「セッションの repo なら default branch への push も通常操作」と明示しているため、classifier は main/master を止めない。`permissions.ask` のパターンは `main` の前に空白を要求するので refspec 形（`HEAD:main`）を捕捉できない
- `scope-gh-pr-create.sh`: classifier の `Create Public Surface` が扱うのは「別の repo / org を狙う PR」で、セッション中の repo の owner が信頼範囲かどうかは判定しない。owner は決定論的に判定できるので hook に置く

## 採用しない設定（実測済み）

- **「道具の列挙」で防御を書かない**: インタプリタ名（`python` 等）や読取コマンド名（`cat` 等）を deny / hook で列挙しても、`perl -e`・`node -e`・`bash -c`・`tr < f`・`while read` リダイレクト・一旦ファイルに書いてから実行、で回避できる（実測済み）。道具の集合は開いている。Bash tool を与える以上、任意コード実行は前提であり、境界は sandbox（`filesystem` の allow/deny・`network.strictAllowlist`・`allowUnsandboxedCommands: false`）と auto モードの classifier が持つ。道具の選好（`python` より `jaq` / `ryl`）は防御ではなくスタイルなので `claude/CLAUDE.md` 側に置く
- **hook の判定基準は「参照される資産」側に置く**: 認証情報のパス・環境変数名・push 先ブランチ・PR 先 owner は閉じた集合なので、そちらを列挙してコマンド文字列全体に照合する。現行 hook は全てこの形。ただし対象が閉じていても綴り方は閉じていないので、パスを照合する前にクォート・重複スラッシュ・`/./`・先頭 `./` を正規化する。それでもパスを分割する形（`cd <dir> && cat <rest>`）や変数経由は通るため、hook は sandbox に残った穴の二次防御と位置づけ、単独の境界にしない
- `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` は**設定しない**: Anthropic・クラウドプロバイダ系の認証情報を全サブプロセスから strip する機能だが、この環境では有効化すると Bash tool が広範に機能不全を起こし、`permissions.defaultMode: "auto"` も正しく反映されなかった（2026-07 実機確認・v2.1.220）。再度有効化を検討する場合は、まず狭いスコープで再現するか確認すること
- 認証情報のパスは `filesystem.denyRead` ではなく `sandbox.credentials.files` に置く。docs は `credentials.files` の `mode: "deny"` を「`filesystem.denyRead` が適用するのと同じ制限」と書いており、パスのプレフィックス規則もスコープ間のマージも共通。`credentials` 側は「これは認証情報だ」と宣言でき、`mode` が `deny` しか無いので広げる誤用も起きない。`filesystem.denyRead` は `~/` 全体のような広域ポリシーに使う
- allow の内側の deny は効く（v2.1.226・macOS/Seatbelt で実測。`allowRead` した親の中の 1 ファイル・1 ディレクトリを deny すると、そこだけ EPERM になる）。ただし判定は**解決後のパス**で行われるので、symlink 経由の表記で書いた deny は実体に一致せず失効する。deny を足したら新規セッションで実際に読めなくなることを確認する
- `~/.config` は `~/repos/github.com/halkn/dotfiles/.config` への symlink。そのため `~/.config/<name>` 表記の deny は dir 単位でも file 単位でも効かず（実体は `allowRead: "."` の内側にある repo 配下）、逆に `~/.config` を allowRead から外して `~/.config/mise` だけを列挙する形も効かない（symlink 本体が `~/` の denyRead 側に残り辿れない）。**閉じたいものは実体パスで書く**: `~/repos/github.com/halkn/dotfiles/.config/gh` を deny すると symlink 経由の read も EPERM になる（v2.1.226 で実測）。symlink でない環境のために `~/.config/gh` 表記も併記する
- repo に追跡されている公開設定（`.config/snowflake/config.toml` 等）は deny しない。守る対象が無いうえ、repo 内の追跡ファイルを Bash から読めなくするだけになる。閉じる対象は「追跡外で認証情報を持つもの」に限る
- `permissions.deny` の `Read(...)` は sandbox の read deny にも降りるが、降りるのは**ファイル名パターンだけ**。`//**/.env`・`//**/*.pem`・`//**/id_rsa*` は書込可能なディレクトリの中でも EPERM になる一方、subtree 形（`//**/.ssh/**`・`//**/secrets/**`・`//**/credentials/**`）は Read tool にしか効かず、Bash からは配下のファイルが読める（v2.1.226 実測。`.ssh/id_rsa` が止まるのは `id_rsa*` の側にマッチするため）。Bash からも塞ぐなら `sandbox.credentials.files` か `sandbox.filesystem.denyRead` に書く
- `mise bootstrap` は `--dry-run` / `status` でも `[bootstrap.repos]` の clone 先（`~/.local/share/zsh/plugins/`）を読むので、そこが allowRead に無いと repos ステップが `Operation not permitted (os error 1)`（`src/system/repos.rs`）で落ちる。permission が通っていても起きるので、permission と sandbox のどちらで止まったかは切り分けてから直す（v2.1.226・mise 2026.8.3 で実測）
- `mise bootstrap --dry-run` の差分は、`[dotfiles]` の配置先が全て allowRead に入っていないと信用できない。`~/.zshenv` のように `~/` の denyRead 配下にあるターゲットは lstat が EPERM になり、mise はそれを「symlink 未作成」と見なして `ln -sf` を差分として出す。エラーにならないぶん、落ちる repos ステップより気づきにくい。`[dotfiles]` にターゲットを足したら配置先を allowRead にも足す（v2.1.226・mise 2026.8.3 で実測）
- `allowRead` を削ったら `mise run lint` を通す。ツールが自分の設定を読めなくなっても多くは失敗せず、黙って既定値で動く。壊れたことが**結果の変化**としてしか出ないので、read を狭める変更は必ず lint で確認する
- sandbox から除外したコマンド（`excludedCommands`）には filesystem 制限も `credentials.envVars` の deny も効かない。`gh` は除外しているので、`~/.config/gh` を実体パスで閉じても `gh` 自身の認証は壊れない。逆に `az` は sandbox 内で動くため `~/.azure` は allowRead が必要で、こちらは hook でしか守れない
- PreToolUse hook に `if` フィルタ（permission rule 構文）を使わない: prefix マッチのため `git push && gh pr create ...` のような複合コマンドで hook 自体がスキップされ、スクリプト側のセグメント解析による防御が無効化される
- hook の停止は `exit 2` で書く。docs 上、exit 2 は permission rule の評価より前に tool call を止めるので allow ルールにも勝つ。JSON の `permissionDecision` は permission rule を飛び越えられない（`"allow"` を返しても deny / ask ルールは評価される）。逆に確認を出したいだけなら JSON の `"ask"` を使う。これは auto モードの classifier を迂回してプロンプトを出す唯一の hook 手段。exit 1 は non-blocking なので停止に使わない
- PreToolUse hook の `command` にスクリプトパスを直接書かない: スクリプト不在時は exit 127 の non-blocking error になりガードが無言で失効する。`h=<path>; [ -x "$h" ] || { echo ... >&2; exit 2; }; exec "$h"` の形で包み、欠落を exit 2 でブロックさせる。`claude/hooks/` に追加したスクリプトは `mise bootstrap` を実行するまで `~/.claude/hooks/` に symlink されないため、この失効は容易に起きる
- `sandbox.network.tlsTerminate` + `sandbox.credentials.envVars` の `mode: "mask"` は**採用しない**: mask は sandbox proxy が sentinel を実値へ差し替える仕組みなので、`excludedCommands` でサンドボックス外を走る `gh` には適用されない。対象も環境変数に限られ、この環境の gh token は keychain / `~/.config/gh` 側にある。加えて `tlsTerminate` は experimental かつ全サンドボックスコマンドの TLS を終端するため、Go/Rust 製ツールの TLS 検証失敗リスクを広げる。`GH_TOKEN` / `GITHUB_TOKEN` は `deny` のまま据え置く

## sandbox.excludedCommands の方針

- `gh *` の除外は**維持する**。sandbox 内で `gh` を走らせると 2 系統で壊れる: keyring のトークンを引けず `The token in default is invalid.`、ネットワークは `tls: failed to verify certificate: x509: OSStatus -26276`（v2.1.226・macOS で実測。docs の Troubleshooting も Seatbelt 下の Go 製 CLI に対して `excludedCommands` を推奨している）。監査のたびに再検討しない
- 除外はツール呼び出しのコマンド文字列に対するマッチなので、`bash script.sh` の中から `gh` を呼ぶと除外は効かず sandbox 内で上記の失敗になる。スクリプト経由で `gh` を使わない
- `git` はネットワーク／認証を要するサブコマンド（`push`・`fetch`・`pull`・`clone`・`ls-remote`・`remote update|prune`・`submodule`）だけを除外する。`git *` 全体を除外すると `filesystem.denyRead: ["~/"]` が git 経由で素通しになる。除外していない現在は `git hash-object <denyRead 配下>` が EPERM になることを確認済み（v2.1.226）。docs は linked worktree の共有 `.git` への書き込みを明示的に許可しており、ローカル操作はサンドボックス内で動く前提
- push は `.config/git/config` の `pushInsteadOf` により SSH。HTTPS 化しても credential helper が Seatbelt 下で通らず、`allowUnsandboxedCommands: false` のため即ハードエラーになるので、ネットワーク系 git は除外に残す
- 引数なし形（`git push` 等）とワイルドカード形を併記する。除外に追加する前に、そのサブコマンドがサンドボックス内で実際に失敗することを確認する

## native worktree の扱い

Claude Code は `--worktree` / `EnterWorktree` / subagent の `isolation: worktree` で `<repo>/.claude/worktrees/<name>` に `worktree-<name>` branch の checkout を作る（docs 記載・v2.1.226）。ここは ephemeral・agent-managed の領域で、削除は Claude Code 側（変更なしなら即時、変更があれば `cleanupPeriodDays` に従う sweep）が持つ。人間が継続して使う worktree は `wt` / herdr の領域（`~/.local/share/herdr/worktrees/`）で、両者を同じ場所に集約しない。

- `worktree.baseRef` は `"head"`。既定の `"fresh"` は remote の default branch から分岐するので、herdr worktree の feature branch 上で立てた subagent が作業対象のコミットを持たない。docs も in-progress work を隔離する場合の値として `"head"` を挙げている。worktree 内では**その worktree の HEAD** に解決される
- `.claude/worktrees/` は `.gitignore` に入れる。このリポジトリの `.claude/` は追跡対象なので、入れないと agent の checkout が main checkout に untracked で現れる
- `.worktreeinclude` は**置かない**: gitignored file をコピーする機能だが、このリポジトリの gitignored file は machine-local な identity（`.config/git/config.local`・`.zshenv.local`）と `.config/gh/`（認証情報）で、agent の checkout へ複製すると露出面が広がる。tracked file だけで `mise run lint` は成立する。必要が出たら、複製してよいファイルを個別に列挙してから置く
- native worktree の中で `mise trust` は要らない。mise は linked worktree の config を main checkout の同じパスの trust で扱う（`mise trust --help`・mise 2026.8.3。paranoid mode ではこの共有が切れる）
- **`git worktree add` を Bash から実行しない**: sandbox は `.zshrc` / `.bashrc` への書込をリポジトリ内のどの階層でも拒否するため、この 2 つを含むこのリポジトリでは checkout が `unable to create file .config/zsh/.zshrc: Operation not permitted` で失敗し、作成途中の worktree だけが残る（v2.1.226・macOS で実測）。Claude Code 自身が作る worktree はこの制限を受けない（`isolation: worktree` の subagent が `.config/zsh/.zshrc` を持つ checkout を得られることを確認済み）。worktree が要るときは native の仕組みを使い、人間の作業場は `wt` から作る
- `.claude` / `.claude/worktrees` / worktree 自身が symlink だと Claude Code は作成を拒否する。`~/.config` のようにこのリポジトリへ symlink を張る運用を `.claude/` 配下へ広げない
- **worktree 内では設定ファイルの自己保護が外れる**（v2.1.226・macOS で実測）。絶対パスで表現される deny（`<repo>/claude/settings.json`・`<repo>/.claude/settings.json`・`<repo>/claude/CLAUDE.md`・`<repo>/.claude/hooks` 等）は `.claude/worktrees/<name>/` 配下の複製に一致せず、隔離した subagent はこれらを書き換えられる。一方 glob 形の deny（`.zshrc` 等）は階層を問わず効く。worktree で走らせる agent に settings・hook を触らせる作業を渡さず、その diff は merge 前に人間が読む

## Subagent の runtime 制御

委譲するかどうかの判断基準は `claude/CLAUDE.md`。ここに置くのは、その基準がどこまで runtime に担保されているか（docs 記載・v2.1.226 時点）。

- **同時実行数**: 既定 20。超えた spawn は `Concurrent subagent limit reached` で失敗し、retry しないよう指示が返る。走っている数が減れば再び通る。session 通算の spawn 数に上限は無い。`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` で変更（v2.1.217 以降。ultracode 有効時は非適用）
- **nesting の深さ**: 既定 3 層。上限に達した subagent からは `Agent` tool が外れる（fork は残るが呼ぶとエラー）。`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` で変更、`1` で nesting 無効。既定値はバージョンで動いている（v2.1.172–216 は 5 固定、v2.1.217–218 は 1、v2.1.219 以降 3）ので、この値を前提にした指示を書かない
- **既定は background**（v2.1.198 以降）。結果は後のターンの完了通知で届く。background subagent は built-in tool の集合が縮む（`Read` / `Grep` / `Glob` / `Bash` / `Edit` / `Write` / `WebFetch` / `Skill` 等に限られ、それ以外は `tools` に書いても外れる）。fork は両方のフィルタを受けない
- **fork** は会話・system prompt・tool 構成をそのまま継承する subagent。`/subtask`（v2.1.212 以降。それ以前は `/fork`）。`CLAUDE_CODE_FORK_SUBAGENT=1` にすると全 subagent が background 固定になる

この 2 つの上限を settings の `env` で override しない。既定は runtime 側の安全弁で、こちらが抑えたいのは「利得の無い委譲」という判断の質であって同時実行数ではない。数値を下げると有効な並列作業まで塞ぐ。

## 手動での追記が必要な設定

- `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙リスト。新しいシークレット系 CLI ツールを導入したら対応する環境変数名をここに追加する。`mode: "deny"` はサンドボックス内のコマンドから当該変数を消す（ダミー変数で動作を確認済み・v2.1.226）が、`excludedCommands` は sandbox 外で走るため適用されない。そちらは `claude/hooks/block-secret-read.sh` の環境変数展開チェックが受け持つ
- `claude/settings.json` は public repo にコミットされるため `autoMode.environment` に社内・仕事用のインフラ情報（組織名・内部ホスト名等）を書かない。仕事用の trusted infrastructure は `/Library/Application Support/ClaudeCode/managed-settings.json`（repo 外・追跡外）に記述する

## Auto モードの前提

`permissions.defaultMode` は `auto`。permission prompt の代わりに classifier（分類モデル）が各アクションを評価する。

- `autoMode`（および `permissions.defaultMode: "auto"`）は user settings（`~/.claude/settings.json`）・managed settings・`--settings` フラグからのみ読まれる仕様で、`.claude/settings.json` / `.claude/settings.local.json` からは読まれない（`permissions.defaultMode` は v2.1.207、`autoMode` ブロックは v2.1.219 以降。repo や build step が自分に auto モードや trusted infrastructure を付与できないようにするため）
- `autoMode.classifyAllShell: true` により、auto モード中は `permissions.allow` の Bash ルール（`Bash(git *)` 等）が全て停止し、全シェルコマンドが classifier 経由になる。allow リストは `acceptEdits` 等の他モードへ切り替えたときの fallback として残している
- `permissions.allow` は auto モードでは死んでいるので、判断基準は「他モードへフォールバックしたときに無確認で通っても安全か」だけ。サブコマンドを明示した read-only 形にとどめ、`Bash(git *)` のような動詞を跨ぐワイルドカードは置かない（`git -c core.pager=<cmd> log` や `gh alias set --shell` のように、`*` が空白を跨いで書き込み・任意実行サブコマンドを取り込む）
- 破壊的だが正当な用途もある操作（`git reset --hard` / `git clean -f` / `git worktree remove` / `uv self update` / `mise bootstrap --force-dotfiles` 等）は deny ではなく `permissions.ask` に置く。deny は代替手段を塞ぐだけだが、ask なら auto モード中も classifier より前に確認が入る
- `permissions.deny` に残すのは「取り返しがつかない」かつ「正当な用途がほぼ無い」ものだけ。回避可能な道具の列挙と、sandbox が既に決定論的に制御しているもの（書込先は write allowlist、送信先は network allowlist）は deny に置かない。git で戻せる変更（lockfile・依存）も deny の対象にしない
- `sandbox.network.strictAllowlist` を exfiltration の防波堤として数えない。制御するのは送信先だけで中身ではなく、docs は `github.com` のような広いドメインの許可について「can create paths for data exfiltration」と明記し、proxy が TLS を検査せず client 提供のホスト名で判断するため domain fronting で allowlist 外へ到達しうるとまで書いている。allowlist 内にも remote code path（`codeload.github.com`）と exfiltration path（`api.github.com` の gist）が残る。ネットワーク系の deny を外すときは、残余リスクを負うのが classifier だと承知の上で外す。非 HTTP の生ソケット（`nc` / `ssh` / `scp`）は proxy の対象外になりうるので deny に残す
- 環境を変える操作は「入口が閉じているか」で書き分ける。`mise run setup|sync|update` のような task 名は閉じた集合なので、完全一致で ask に列挙して人間のチェックポイントにする。`mise bootstrap` のようにサブコマンドとフラグの形が開いているものは列挙しない。mutating 形を網羅しようとすると際限なく伸び、それでも alias 表記（`packages up`）や稀なグローバルフラグは漏れる
- 開いている側は、両端と「無確認で走る形」だけをルールで固定し、残りは classifier に渡す: 他ホストへ作用するもの（`mise bootstrap remote`）は deny、取り返しがつかないが正当な用途があるもの（`mise bootstrap --force-dotfiles`）と、ツール側の確認を落とす形（`--yes` / `-y`。短縮形も併記する）は ask、完全に read-only な形（`status` / `plan` / `--dry-run`）は allow
- ask は allow より先に評価される。`Bash(mise bootstrap*)` のような広い prefix を ask に置くと read-only 形まで毎回プロンプトになり、同じ形を allow へ足しても外れない。read-only 形を通したいなら ask 側を狭めるしかない
- ルールの置き場所は「そのコマンドを複数のリポジトリで打つか」で決める。単一リポジトリでしか実行しないもの（`mise bootstrap` / `mise run setup|sync|update`）は `.claude/settings.json` に置き、`claude/settings.json` には汎用のもの（`mise tasks` 等）だけを残す。`permissions` の allow / deny / ask は project settings からも読まれる（読まれないのは `defaultMode` と `autoMode`）。sandbox の allowRead / allowWrite も同じ基準で分ける
- ask / deny のパターンは、実際に打たれる形を `mise.toml` や `README.md` で確認してから書く。`mise bootstrap` のようにサブコマンド・フラグの形が一定しないものは、`*` 無しの完全一致では実際の呼び出しを 1 つも捕捉できない
- deny のパターンはオプションの等号形も併記する。`--http-method post` だけを書くと `--http-method=POST` がすり抜ける
- パターンの照合規則（docs 記載。ここを誤解すると書いたつもりのルールが効かない）:
  - `*` は空白を跨いで任意長にマッチする。`Bash(git * main)` は `git push origin main` にも `git merge main` にもマッチする
  - 末尾 `*` の直前に空白があると語境界を要求する。`Bash(ls *)` は `lsof` にマッチせず、`Bash(ls*)` はマッチする
  - 複合コマンドは `&&` `||` `;` `|` `|&` `&` と改行で分割され、各サブコマンドが独立に照合される。パイプで繋いでも deny は回避できない一方、allow は全サブコマンドが一致しないと成立しない
  - `watch` / `setsid` / `flock` などの exec wrapper と `find -exec|-delete` は prefix ルールで自動承認されない。hook 側でもこれらを読み飛ばして実行対象まで進める（オペランドを取る `timeout N` / `flock FILE` は単純な読み飛ばしでは解決できないので、hook は捕捉できない前提で扱う）
- `classifyAllShell` が停止するのは allow ルールだけで、`permissions.ask` は auto モードでも classifier より前に評価され必ずプロンプトを出す。docs も push / PR に人間のチェックポイントを置く推奨手段として `permissions.ask` を挙げている。よって `permissions.ask` は他モード用の fallback ではなく auto モードでの一次ガード
- 既定の classifier ルールは `claude auto-mode defaults` で読める。ここの allow / soft_deny を先に読んでから hook を足す・消すを判断する
- main/master への直接 push は auto モードの既定では許可される（allow ルール `Git Push Destination`: 「Pushing to any branch of the session's repo is ordinary — the default branch included」。v2.1.226 で確認）。このリポジトリでは 2 層で担保する: `permissions.ask` の `Bash(git push * main*)` 等が素直な形を捕捉し、`git push origin HEAD:main` のように `main` の前に空白が無く pattern がマッチしない refspec 形式は `claude/hooks/block-main-push.sh` が解釈して `ask` する。`autoMode` 側には重複ルールを置いていない
