# sandbox と permissions

## filesystem の実測

- **「道具の列挙」で防御を書かない**: インタプリタ名（`python` 等）や読取コマンド名（`cat` 等）を deny / hook で列挙しても、`perl -e`・`node -e`・`bash -c`・`tr < f`・`while read` リダイレクト・一旦ファイルに書いてから実行、で回避できる（実測済み）。境界は sandbox（`filesystem` の allow/deny・`network.strictAllowlist`・`allowUnsandboxedCommands: false`）と auto モードの classifier が持つ
- 認証情報のパスは `filesystem.denyRead` ではなく `sandbox.credentials.files` に置く。docs は `credentials.files` の `mode: "deny"` を「`filesystem.denyRead` が適用するのと同じ制限」と書いており、パスのプレフィックス規則もスコープ間のマージも共通。`credentials` 側は「これは認証情報だ」と宣言でき、`mode` が `deny` しか無いので広げる誤用も起きない。`filesystem.denyRead` は `~/` 全体のような広域ポリシーに使う
- allow の内側の deny は効く（v2.1.226・macOS/Seatbelt で実測。`allowRead` した親の中の 1 ファイル・1 ディレクトリを deny すると、そこだけ EPERM になる）。ただし判定は**解決後のパス**で行われるので、symlink 経由の表記で書いた deny は実体に一致せず失効する。deny を足したら新規セッションで実際に読めなくなることを確認する
- `~/.config` は `~/repos/github.com/halkn/dotfiles/.config` への symlink。そのため `~/.config/<name>` 表記の deny は dir 単位でも file 単位でも効かず（実体は `allowRead: "."` の内側にある repo 配下）、逆に `~/.config` を allowRead から外して `~/.config/mise` だけを列挙する形も効かない（symlink 本体が `~/` の denyRead 側に残り辿れない）。**閉じたいものは実体パスで書く**: `~/repos/github.com/halkn/dotfiles/.config/gh` を deny すると symlink 経由の read も EPERM になる（v2.1.226 で実測）。symlink でない環境のために `~/.config/gh` 表記も併記する
- Claude Code の自己保護が届くのは、ロード元のパス（cwd とその上位の `.claude/**`・`.mcp.json`、`~/.claude/**`）と、そこに張られた symlink の先だけ。`claude/hooks/*.sh`・`claude/statusline-command.sh` は Claude Code が実行するが symlink 先保護の対象外で、`mise.toml` と同様に Bash から書けた（v2.1.229・macOS で実測）。実体を repo 側に持つ設定・スクリプトは `filesystem.denyWrite` に実体パスで列挙する。副作用として、`claude/` 配下を変更する `git merge` / `git switch` は sandbox 内で `unable to unlink old` になる（docs の Troubleshooting 記載）。`mise.toml` は日常的に編集するので deny に置かず、classifier に委ねる
- `~/.claude` は `filesystem.allowRead` に書かなくても読める（組み込みの allow に入る。v2.1.259・macOS で実測）。`~/.claude/skills` のような配下の個別指定は要らない
- `~/.cache` 配下にはログインシェルが起動時に実行するキャッシュがある（`.zshrc` が `$XDG_CACHE_HOME/zsh/uv_completion.zsh` を source、`compinit -C` が `.zcompdump` を検査なしで読む、fast-syntax-highlighting が `~/.cache/fsh/*.zsh` を読む）。そこへの書込はサンドボックス外・classifier 外で次のシェル起動時に実行される。ツール別に列挙する現在の形では、`~/.cache` にあるのは `uv` / `mise` / `rumdl` / `shuck` の 4 つ（v2.1.259・macOS）
- `~/.cache/gh` は allowlist に入れないだけで read / write とも EPERM になる（v2.1.259 で実測）。`credentials.files` や `denyWrite` に重ねて書く必要は無い
- repo に追跡されている公開設定（`.config/snowflake/config.toml` 等）は deny しない。守る対象が無いうえ、repo 内の追跡ファイルを Bash から読めなくするだけになる。閉じる対象は「追跡外で認証情報を持つもの」に限る
- `permissions.deny` の `Read(...)` は sandbox の read deny にも降りるが、降りるのは**ファイル名パターンだけ**。`//**/.env`・`//**/*.pem`・`//**/id_rsa*` は書込可能なディレクトリの中でも EPERM になる一方、subtree 形（`//**/.ssh/**`・`//**/secrets/**`・`//**/credentials/**`）は Read tool にしか効かず、Bash からは配下のファイルが読める（v2.1.226 実測。`.ssh/id_rsa` が止まるのは `id_rsa*` の側にマッチするため）。Bash からも塞ぐなら `sandbox.credentials.files` か `sandbox.filesystem.denyRead` に書く
- `mise bootstrap` は `--dry-run` / `status` でも `[bootstrap.repos]` の clone 先（`~/.local/share/zsh/plugins/`）を読むので、そこが allowRead に無いと repos ステップが `Operation not permitted (os error 1)`（`src/system/repos.rs`）で落ちる。permission が通っていても起きるので、permission と sandbox のどちらで止まったかは切り分けてから直す（v2.1.226・mise 2026.8.3 で実測）
- `mise bootstrap --dry-run` の差分は、`[dotfiles]` の配置先が全て allowRead に入っていないと信用できない。`~/.zshenv` のように `~/` の denyRead 配下にあるターゲットは lstat が EPERM になり、mise はそれを「symlink 未作成」と見なして `ln -sf` を差分として出す。エラーにならないぶん、落ちる repos ステップより気づきにくい。`[dotfiles]` にターゲットを足したら配置先を allowRead にも足す（v2.1.226・mise 2026.8.3 で実測）
- `allowRead` を削ったら `mise run lint` を通す。ツールが自分の設定を読めなくなっても多くは失敗せず、黙って既定値で動く。壊れたことが**結果の変化**としてしか出ないので、read を狭める変更は必ず lint で確認する
- sandbox から除外したコマンド（`excludedCommands`）には filesystem 制限も `credentials.envVars` の deny も効かない。`gh` は除外しているので、`~/.config/gh` を実体パスで閉じても `gh` 自身の認証は壊れない。逆に `az` は sandbox 内で動くため `~/.azure` は allowRead が必要で、こちらは hook でしか守れない
- `credentials.envVars` の `mode: "mask"` は sandbox proxy が sentinel を実値へ差し替える仕組みなので、`excludedCommands` でサンドボックス外を走る `gh` には適用されない

## sandbox.excludedCommands の方針

- `gh *` の除外は**維持する**。sandbox 内で `gh` を走らせると 2 系統で壊れる: keyring のトークンを引けず `The token in default is invalid.`、ネットワークは `tls: failed to verify certificate: x509: OSStatus -26276`（v2.1.226・macOS で実測。docs の Troubleshooting も Seatbelt 下の Go 製 CLI に対して `excludedCommands` を推奨している）。監査のたびに再検討しない
- 除外はツール呼び出しのコマンド文字列に対するマッチなので、`bash script.sh` の中から `gh` を呼ぶと除外は効かず sandbox 内で上記の失敗になる。スクリプト経由で `gh` を使わない
- `git` はネットワーク／認証を要するサブコマンド（`push`・`fetch`・`pull`・`clone`・`ls-remote`・`remote update|prune`・`submodule`）だけを除外する。`git *` 全体を除外すると `filesystem.denyRead: ["~/"]` が git 経由で素通しになる。除外していない現在は `git hash-object <denyRead 配下>` が EPERM になることを確認済み（v2.1.226）。docs は linked worktree の共有 `.git` への書き込みを明示的に許可しており、ローカル操作はサンドボックス内で動く前提
- push は `.config/git/config` の `pushInsteadOf` により SSH。HTTPS 化しても credential helper が Seatbelt 下で通らず、`allowUnsandboxedCommands: false` のため即ハードエラーになるので、ネットワーク系 git は除外に残す
- 引数なし形（`git push` 等）とワイルドカード形を併記する。除外に追加する前に、そのサブコマンドがサンドボックス内で実際に失敗することを確認する
- `az login` のブラウザ認証は Apple Events がサンドボックスで塞がれるため失敗する（docs: エラー `-600`）。これを通すために `az *` を除外しない。ログインはユーザーが Claude Code の外のターミナルで済ませ、Claude 側は `~/.azure` のトークンキャッシュを使う
- hunk の session daemon は loopback の websocket broker（既定 `127.0.0.1:47657`）で、sandbox 内からは connect() で拒否される。`sandbox.network` に outbound loopback を許可するキーは無い（`allowLocalBinding` は bind 側）ので `hunk session *` は除外に残す（v2.1.251・macOS・hunk 0.20.0）。到達性の判定に `hunk session list` の出力を使わない: 存在しないポートを指しても同じ「No active Hunk sessions.」を返す。session id・files・comments が実データで返ることで判定する
- `hunk session` に `permissions.allow` は要らない。auto モードの classifier が承認する（allow に無い `hunk session comment rm` がプロンプトなしで通ることを確認済み。v2.1.251）

## Auto モードの前提

`permissions.defaultMode` は `auto`。permission prompt の代わりに classifier（分類モデル）が各アクションを評価する。

- `autoMode`（および `permissions.defaultMode: "auto"`）は user settings（`~/.claude/settings.json`）・managed settings・`--settings` フラグからのみ読まれる仕様で、`.claude/settings.json` / `.claude/settings.local.json` からは読まれない（`permissions.defaultMode` は v2.1.207、`autoMode` ブロックは v2.1.219 以降。repo や build step が自分に auto モードや trusted infrastructure を付与できないようにするため）
- `autoMode.classifyAllShell: true` により、auto モード中は `permissions.allow` の Bash ルール（`Bash(git *)` 等）が全て停止し、全シェルコマンドが classifier 経由になる。allow リストは `acceptEdits` 等の他モードへ切り替えたときの fallback として残している
- `permissions.allow` は auto モードでは死んでいるので、判断基準は「他モードへフォールバックしたときに無確認で通っても安全か」だけ。サブコマンドを明示した read-only 形にとどめ、`Bash(git *)` のような動詞を跨ぐワイルドカードは置かない（`git -c core.pager=<cmd> log` や `gh alias set --shell` のように、`*` が空白を跨いで書き込み・任意実行サブコマンドを取り込む）
- `classifyAllShell` が停止するのは allow ルールだけで、`permissions.ask` は auto モードでも classifier より前に評価され必ずプロンプトを出す。docs も push / PR に人間のチェックポイントを置く推奨手段として `permissions.ask` を挙げている。よって `permissions.ask` は他モード用の fallback ではなく auto モードでの一次ガード
- ask は allow より先に評価される。`Bash(mise bootstrap*)` のような広い prefix を ask に置くと read-only 形まで毎回プロンプトになり、同じ形を allow へ足しても外れない。read-only 形を通したいなら ask 側を狭めるしかない
- `sandbox.network.strictAllowlist` を exfiltration の防波堤として数えない。制御するのは送信先だけで、allowlist 内にも remote code path（`codeload.github.com`）と exfiltration path（`api.github.com` の gist）が残り、proxy は TLS を検査せず client 提供のホスト名で判断する（docs 記載）。非 HTTP の生ソケット（`nc` / `ssh` / `scp`）は proxy の対象外になりうるので deny に残す
- 環境を変える操作は「入口が閉じているか」で書き分ける。`mise run setup|sync|update` のような task 名は閉じた集合なので、完全一致で ask に列挙して人間のチェックポイントにする。`mise bootstrap` のようにサブコマンドとフラグの形が開いているものは列挙しない。mutating 形を網羅しようとすると際限なく伸び、それでも alias 表記（`packages up`）や稀なグローバルフラグは漏れる
- 開いている側は、両端と「無確認で走る形」だけをルールで固定し、残りは classifier に渡す: 他ホストへ作用するもの（`mise bootstrap remote`）は deny、取り返しがつかないが正当な用途があるもの（`mise bootstrap --force-dotfiles`）と、ツール側の確認を落とす形（`--yes` / `-y`。短縮形も併記する）は ask、完全に read-only な形（`status` / `plan` / `--dry-run`）は allow
- ask / deny のパターンは、実際に打たれる形を `mise.toml` や `README.md` で確認してから書く。`mise bootstrap` のようにサブコマンド・フラグの形が一定しないものは、`*` 無しの完全一致では実際の呼び出しを 1 つも捕捉できない
- deny のパターンはオプションの等号形も併記する。`--http-method post` だけを書くと `--http-method=POST` がすり抜ける
- 既定の classifier ルールは `claude auto-mode defaults` で読める。ここの allow / soft_deny を先に読んでから hook を足す・消すを判断する
- soft_deny の `Irreversible Local Destruction` は `git reset --hard` / `git checkout -- .` / `git restore .` / `git clean -fd` / `git stash drop|clear` / `git worktree remove --force` を、`Remote Repoint` は `git remote add|set-url` を、`Unauthorized Persistence` は cron 登録・git hook・shell profile への追記を名指ししている（v2.1.259 で確認）。permissions 側に同じ形を置くと、ユーザーが明示的に指示した場合でも確認が出る
- classifier が名指ししていても、`allow` の例外や「ユーザーが指示した」判定で通る形は ask に残す。`git config alias.*` は `Unauthorized Persistence` の列挙（shell profile・cron・systemd・git hook）に含まれず、`Remote Repoint` も `remote.<name>.url` しか名指ししないので、classifier 任せにはできない
- force push を deny に置かない。`Bash(git push --force*)` は `--force-with-lease` にもマッチするので、deny にすると安全側の形まで塞がる。soft_deny の `Git Destructive` が force push と remote ブランチ削除を拾うので、permissions 側は ask で十分

## パターンの照合規則（docs 記載）

ここを誤解すると書いたつもりのルールが効かない。

- `*` は空白を跨いで任意長にマッチする。`Bash(git * main)` は `git push origin main` にも `git merge main` にもマッチする
- 末尾 `*` の直前に空白があると語境界を要求する。`Bash(ls *)` は `lsof` にマッチせず、`Bash(ls*)` はマッチする
- 複合コマンドは `&&` `||` `;` `|` `|&` `&` と改行で分割され、各サブコマンドが独立に照合される。パイプで繋いでも deny は回避できない一方、allow は全サブコマンドが一致しないと成立しない
- `watch` / `setsid` / `flock` などの exec wrapper と `find -exec|-delete` は prefix ルールで自動承認されない。hook 側でもこれらを読み飛ばして実行対象まで進める（オペランドを取る `timeout N` / `flock FILE` は単純な読み飛ばしでは解決できないので、hook は捕捉できない前提で扱う）
