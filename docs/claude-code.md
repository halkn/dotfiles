# Claude Code 設定の設計

`claude/settings.json`（全リポジトリ共通）と `.claude/settings.json`（このリポジトリ専用）は JSON でコメントを書けないため、設定の理由はこの doc が持つ。各 hook の理由は `claude/hooks/*.sh` の冒頭コメントにある。

`claude/` の中身は `~/.claude/` にリンクされ、全てのプロジェクトの Claude Code に効く。全プロジェクト共通の指示は `claude/CLAUDE.md` に、このリポジトリ専用の指示は `AGENTS.md` に書く。`claude/` は sandbox で Bash から書けないので、Edit / Write tool で編集する。

「設定の理由」の節は実測に基づく。確認した環境は Claude Code v2.1.220〜2.1.280・macOS（Seatbelt）で、WSL（bubblewrap）には当てはめない。記述と実際の挙動が食い違ったら、公式 docs を読むか測り直してから設定を変える。

## 使い方の原則

- 作業の起点は、Claude Code を起動したリポジトリ。Bash からの読取はホームを閉じ、そのリポジトリだけを `.claude/settings.local.json` の `sandbox.filesystem.allowRead: ["./"]` で開ける。ユーザー設定の相対パスは `~/.claude` を指すので、ユーザー設定では開けられない。セッション中に作業ディレクトリを動かさない
- sandbox と `permissions.ask` は、失敗やモードの切替で外れないようにする。sandbox を起動できないときの素通り、sandbox の外での再実行、ask を飛ばすモードを閉じる
- Claude Code 本体の更新は `mise run update` に一本化し、自動更新は止める。プラグインの更新は Claude Code に任せる

## 3 つの層の使い分け

| 層 | 性質 | 置くもの |
| --- | --- | --- |
| CLAUDE.md / AGENTS.md | 強制力の無い context | 規約・判断基準 |
| `permissions` / hook | コマンド文字列の照合なので、書き方を変えればすり抜けられる | sandbox で表せないもの（取り返しのつかない外向きの操作の確認）と、二次防御 |
| `sandbox` | OS が強制する唯一の境界。ただし効くのは Bash だけ | 能力の制限（ファイルの読み書き・送信先） |

書き込みを確実に止めたい対象は、Bash と Edit / Write の両方の経路を塞ぐ。

## ガードを足す・消すときの基準

- sandbox・`permissions`・auto モードの classifier という標準機能で代わりが効かないことを、先に示す
- 防ぐ対象は、道具（インタプリタ名・読取コマンド名）ではなく、守る資産（認証情報のパス・環境変数名・push 先ブランチ）の側で列挙する。道具は代わりがいくらでもあるが、資産の集合は閉じている
- deny に置くのは、取り返しがつかず、正当な用途もほぼ無いものだけ。破壊的でも正当な用途がある操作（`git push --force`・`mise bootstrap --force-dotfiles`）は ask に置く
- classifier の既定ルールが名指ししている操作は、原則として permissions に重ねない。重ねると、ユーザーが明示的に指示した操作にまで確認が出る。指示した後でも人が毎回確かめたい操作（push・ブランチや worktree の削除・ツールの uninstall）だけは、あえて ask に重ねる
- sandbox が制御している書込先・送信先と、git で戻せる変更（lockfile・依存）は deny に置かない
- 入口が閉じている操作（`mise run sync|update`）は完全一致で ask に列挙する。引数の形が開いている操作（`mise bootstrap`）は列挙しきれないので、両端だけを固定し（他ホストへの作用は deny、`--force-dotfiles`・`--yes` を先頭に置いた形は ask、`status`・`plan`・`--dry-run` は allow）、残りは classifier に任せる
- パターンは、実際に打たれる形を確かめてから書く。オプションは `--opt=value` の形も併記する

## 置き場所

- 複数のリポジトリで打つコマンドの許可は `claude/settings.json` に、このリポジトリでしか打たないもの（`mise bootstrap`・`mise run sync|update`）は `.claude/settings.json` に置く。sandbox の `allowRead` / `allowWrite` も同じ基準で分ける
- `claude/settings.json` は public repo にある。仕事用のインフラ情報（組織名・内部ホスト名）は `autoMode.environment` に書かず、追跡外の managed settings に置く
- 認証情報を環境変数で受け取る CLI を導入したら、その変数名を `sandbox.credentials.envVars` に足す

## 設定の理由

### sandbox の filesystem

- 読取は既定で閉じる。`filesystem.denyRead` でホーム全体（`~/`）を閉じ、ツールが必要とする場所だけを `allowRead` で開ける。`allowRead` の項目は全てこの例外
- deny と `credentials.files` は、symlink を解決した後の実体パスで書く。sandbox は解決後のパスで判定するので、`~/.config`（このリポジトリへの symlink）経由の表記だけでは効かない。symlink でない環境のために、`~/.config/...` の表記も併記する
- `~/.config` は丸ごと `allowRead` に入っている。XDG に従うツールの設定は、足さなくても読める
- `claude/` は `denyWrite` に置く。Claude Code の自己保護は settings や CLAUDE.md を守るが、Claude Code が実行する `claude/hooks/*.sh` と statusline のスクリプトは守らないため。副作用として、`claude/` を変える `git switch` / `git merge` は sandbox 内で失敗する。worktree 内の複製（`.claude/worktrees/*/claude/`）はこの deny の対象外
- 認証情報のパスは `filesystem.denyRead` ではなく `sandbox.credentials.files` に置く。認証情報だと宣言でき、許可を広げる方向の誤用も起きない
- `~/.cache` はディレクトリ丸ごとではなく、ツール単位で許可する。ログインシェルが起動時に実行するキャッシュがあり、そこへ書ければ sandbox の外でコードを走らせられるため
- 次のものは `allowRead` に入れる: `~/.claude/skills/` の symlink 先のリポジトリ、`[dotfiles]` の配置先、`[bootstrap.repos]` の clone 先。後の 2 つが無いと `mise bootstrap --dry-run` が失敗するか、誤った差分を出す
- 追跡されている公開設定は deny しない。閉じるのは、追跡外で認証情報を持つものだけ
- `allowRead` を減らしたら `mise run lint` を通す。設定を読めなくなったツールは、エラーを出さずに既定値で動くことが多い

### excludedCommands

- `gh` は除外する。sandbox 内では keyring のトークンを引けず、TLS の検証にも失敗する
- `git` は、ネットワークや認証を使うサブコマンドだけを除外する。`git *` を丸ごと除外すると、git 経由で `denyRead` を素通りできてしまう
- `hunk session *` は除外する。session daemon とは loopback で通信するが、sandbox には外向きの loopback を許可する設定が無い
- `herdr` と `az login` は sandbox 内で動かない。Claude Code の外のターミナルで実行する

### auto モードと permissions

- `autoMode.classifyAllShell` を有効にしているので、auto モードでは `permissions.allow` の Bash ルールが使われない。allow は他のモードへ切り替えたときの予備なので、確認なしで通っても安全な read-only の形だけを、サブコマンドまで明示して書く（`Bash(git *)` は、書込や任意実行を取り込む形まで通してしまう）
- `permissions.ask` は auto モードでも効く。ask は予備ではなく、一次のガードとして扱う
- `git config *alias.*` は ask に置く。alias を作ると、以降のコマンドが permissions のパターンにも hook の照合にも当たらなくなるため
- `sandbox.network.strictAllowlist` を、情報流出を防ぐ仕組みとしては数えない。制御するのは送信先だけで、許可した送信先の中にも流出の経路が残る。proxy を通らない生のソケット（`nc`・`ssh`・`scp`）は deny に残す

### hook

- hook の `command` にはスクリプトのパスを直接書かず、スクリプトが無いときは `exit 2` で止める形で包む。直接書くと、改名・削除やリンクの欠落でスクリプトが無くなったときに、ガードが黙って外れる
- PreToolUse hook に `if` フィルタを使わない。複合コマンドだと hook ごとスキップされ、スクリプト側でのコマンド分解が働かなくなる
- hook スクリプトには実行ビットを付ける。包む形は `-x` で存在を確かめるので、実行ビットが無いと常に止まる
- hook の検査は `mise-tasks/test/hooks` にあり、`lint` から走る
- main / master への push は 4 つの層で止める: `permissions.ask`（素直な形）、`block-main-push.sh`（refspec などの形）、git の `pre-push` hook（`core.hooksPath` で全リポジトリに効き、Claude Code の外の push も止める）、`repo setup` が入れる GitHub の ruleset（hook を飛ばした push も止める）

### worktree

- `worktree.baseRef` は `head` にする。既定値では remote の default branch から分岐するので、feature branch の上で立てた subagent が作業中のコミットを持たない
- `.claude/worktrees/` は `.gitignore` に入れる。`.claude/` は追跡対象なので、入れないと agent の checkout が untracked として見える
- `git worktree add` を Bash から実行しない。sandbox はリポジトリ内の `.zshrc` への書込を拒否するので、checkout が途中で失敗する。worktree は Claude Code 自身の機能で作る
- worktree で走る agent に settings・hook を変える作業を任せない。worktree 内の `claude/` の複製は、自己保護も denyWrite も守らない

## 採用しなかった設定

- `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`: Bash tool が広く動かなくなり、`defaultMode: "auto"` も反映されなかった（v2.1.220）
- `~/.cache` を丸ごと許可し、例外を `denyWrite` で列挙する形: 列挙から漏れたものが開いたままになる
- `credentials.envVars` の `mode: "mask"` と `sandbox.network.tlsTerminate`: mask は sandbox の proxy が値を差し替える仕組みなので、sandbox の外で走る `gh` には効かない
- `az *` の除外: `strictAllowlist` を迂回する送信経路になる
- `"attribution": false`: 2.1.281 より前の CLI は、この値を含む設定ファイルを丸ごと読み飛ばす。`claude/settings.json` は CLI の版が揃わない複数の端末で共有するので、オブジェクト形式（`commit` / `pr` を空にする）を続ける
- `Bash(git push --force*)` の deny: `--force-with-lease` まで塞いでしまう。ask で足りる
- `.worktreeinclude`: gitignore されたファイルを agent の checkout に複製すると、見える範囲が広がる
- subagent の同時実行数・入れ子の深さを下げる設定: 抑えたいのは委譲するかどうかの判断の質で、同時実行数ではない
