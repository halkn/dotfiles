# Claude Code 設定の設計

`claude/settings.json`（全リポジトリ共通）と `.claude/settings.json`（このリポジトリ専用）は JSON でコメントを書けないため、設定の理由はこの doc が持つ。各 hook の理由は `claude/hooks/*.sh` の冒頭コメントにある。

`claude/` の中身は `~/.claude/` にリンクされ、全てのプロジェクトの Claude Code に効く。全プロジェクト共通の指示は `claude/CLAUDE.md` に、このリポジトリ専用の指示は `AGENTS.md` に書く。`claude/` は sandbox で Bash から書けないので、Edit / Write tool で編集する。

好みの設定（表示・言語・エディタ操作・output style・statusline・プラグインの選択）は対象外。既定値と同じ値は書かない。前提は macOS（Seatbelt）で、WSL（bubblewrap）には当てはめない。

## 使い方の原則

- 作業の起点は、Claude Code を起動したリポジトリ。読取は `permissions.blockReadsOutsideWorkingDirectories` でそのリポジトリに限る。ファイルツールはその外を読まず、sandbox もホームを閉じてそのリポジトリを開け直すので、リポジトリごとに `allowRead: ["./"]` を書かない。セッション中に作業ディレクトリを動かさないため、`CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` で Bash コマンドごとに起点へ戻す。push 先や PR 先を作業ディレクトリから解決する hook も、この前提に立つ
- ガードは、失敗やモードの切替で黙って外れないようにする。sandbox を起動できないときの素通り（`sandbox.failIfUnavailable`）、sandbox の外での再実行（`sandbox.allowUnsandboxedCommands`）、ask を飛ばすモード（`permissions.disableBypassPermissionsMode`）、hook スクリプトの欠落（「hook の基準」）を閉じる
- セッションと外をつなぐ経路は、このリポジトリで管理しているものだけにする。外からセッションを操作・指示できる入口（Remote Control、claude.ai から同期される skill）と、セッションの内容を外へ出す経路（Artifact の公開、claude.ai の connector）は開けない
- CLI の認証（`gh auth login`・`az login`）は、Claude Code の外のターミナルで行う。Claude Code は、認証済みのトークンキャッシュを使うだけにする
- Claude Code 本体の更新は `mise run update` に一本化し、自動更新は止める。プラグインの更新は Claude Code に任せる
- Claude Code が作った commit・PR もユーザーの成果物として扱い、Claude Code の署名とセッションへのリンク（`attribution`）を付けない

## 層の使い分け

既定の permission mode は auto にする（`permissions.defaultMode`）。人の確認は ask に明示した操作だけにし、残りは classifier に任せる。

| 層 | 性質 | 置くもの |
| --- | --- | --- |
| CLAUDE.md / AGENTS.md | 強制力の無い context | 規約・判断基準 |
| `permissions` / hook | コマンド文字列の照合なので、書き方を変えればすり抜けられる。ask は auto モードでも classifier より先に効く | sandbox で表せないもの（取り返しのつかない外向きの操作の確認）と、二次防御 |
| auto モードの classifier（`autoMode`） | 文脈で判断するが、確実ではない | コマンド文字列で表せない境界（SQL の中身、どのリポジトリの文脈か） |
| `sandbox` | OS が強制する唯一の境界。ただし効くのは Bash だけ | 能力の制限（ファイルの読み書き・送信先） |

- 確実に止めたい読取・書込は、Bash（sandbox）と Read / Edit / Write tool（`permissions`）の両方の経路を塞ぐ。`permissions` の `Read` deny は sandbox の読取制限にも合流し、`allowRead` で開けた範囲の中でも効く。そのため、どこに置かれても閉じたい認証情報のファイル名（`.env`・鍵）は `Read` deny に、ホーム全体を閉じるのは、ファイルツールと sandbox の両方に効く `blockReadsOutsideWorkingDirectories` に置く。書込も同じで、鍵の置き場所（`~/.ssh`・`~/.gnupg`）は `denyWrite` と `Edit` deny の両方で閉じる
- `autoMode` に足すルールは、ユーザーが対象を名指しして指示すれば通してよいもの（Snowflake の破壊的 DDL）を `soft_deny` に、指示があっても越えない境界（個人と仕事の間の転送）を `hard_deny` に置く
- auto モードでは、全ての shell コマンドを classifier に通す（`autoMode.classifyAllShell`）。allow のパターンは、想定していない引数や script のパスまで通すため。`permissions.allow` の Bash ルールは他のモードに切り替えたときの予備になるので、確認なしで通っても安全な read-only の形だけを、サブコマンドまで明示して書く（`Bash(git *)` は、書込や任意実行を取り込む形まで通してしまう）

## ガードを足す・消すときの基準

- sandbox・`permissions`・auto モードの classifier という標準機能で代わりが効かないことを、先に示す
- 防ぐ対象は、道具（インタプリタ名・読取コマンド名）ではなく、守る資産（認証情報のパス・環境変数名・push 先ブランチ）の側で列挙する。道具は代わりがいくらでもあるが、資産の集合は閉じている
- deny に置くのは、取り返しがつかず、正当な用途もほぼ無いものだけ。例: 権限の昇格（`sudo`）、ローカルの復旧手段を消す操作（`git reflog expire`・`git gc --prune`）、専用のサブコマンドを迂回する汎用の書込口（`az devops invoke` の `--http-method`）、proxy を通らない生のソケット（`nc`・`ssh`・`scp`）。破壊的でも正当な用途がある操作（`git push --force`・`mise bootstrap --force-dotfiles`）は ask に置く
- ガードの照合そのものを外せる操作は ask に置く。例: `git config *alias.*`（alias を作ると、以降のコマンドが permissions のパターンにも hook の照合にも当たらなくなる）
- classifier の既定ルール（`claude auto-mode defaults` で確かめる）が名指ししている操作は、原則として permissions に重ねない。重ねると、ユーザーが明示的に指示した操作にまで確認が出る。指示した後でも人が毎回確かめたい操作（push・未コミットの変更を捨てる `git checkout -f`・ブランチや worktree の削除・ツールの uninstall）だけは、あえて ask に重ねる
- sandbox が制御している書込先・送信先と、git で戻せる変更（lockfile・依存）は deny に置かない
- 入口が閉じている操作（`mise run sync|update`）は完全一致で ask に列挙する。引数の形が開いている操作（`mise bootstrap`）は列挙しきれないので、両端だけを固定し（他ホストへの作用は deny、`--force-dotfiles`・`--yes` を先頭に置いた形は ask、`status`・`plan`・`--dry-run` は allow）、残りは classifier に任せる
- `WebFetch` の allow は、送るものが URL だけで、取得先が公式 docs のものに限る。auto モードの WebFetch は allow が無くても確認なしで通るので、allow の実際の効果は sandbox の送信先への合流（Bash の `curl` で docs を取得し `rg` で原文を引ける）になる。対象は、仕様を原文で確かめる頻度が高い docs（Azure・Snowflake・Claude Code・mise）
- パターンは、実際に打たれる形を確かめてから書く。オプションは `--opt=value` の形も併記する
- 判断の質の問題（subagent に委譲するかどうか）は CLAUDE.md で扱い、設定の上限（同時実行数・入れ子の深さ）で抑えない

## sandbox の基準

- 読取は既定で閉じ、ツールが必要とする場所だけを開ける（`blockReadsOutsideWorkingDirectories` と `allowRead`）。丸ごと開けて例外を列挙する形は取らない。列挙から漏れたものが開いたままになる
- 書込を開けるのは、ツールが自分の状態を書く場所だけ（`~/.azure` のトークンキャッシュ、skill の出力先）。他のプロセスが後で実行する場所には開けない。`~/.cache` をツール単位で開けるのはこのため（ログインシェルが起動時に実行するキャッシュがあり、そこへ書ければ sandbox の外でコードを走らせられる）
- Claude Code が読み込む・実行するファイル（`claude/` 全体）は、組込みの保護に頼らず `denyWrite` と `Edit` の ask で塞ぐ。組込みの保護が覆う範囲は版で変わり、symlink の先にある hook や statusline のスクリプトまで届くとは限らない。副作用として、`claude/` を変える `git switch` / `git merge` は sandbox 内で失敗する
- 追跡されている公開設定は閉じない（`~/.config` は丸ごと開ける）。閉じるのは、追跡外で認証情報を持つものだけで、`sandbox.credentials` に宣言する。認証情報だと宣言でき、許可を広げる方向の誤用も起きない
- 認証情報の閉じ方は、それを使うツールが sandbox のどちら側で動くかで決まる。sandbox の外で動くツール（`gh`）の認証情報は `sandbox.credentials` で閉じる。sandbox の中で動くツール（`az`）の認証情報は、閉じるとツール自身も読めないので `allowRead`（更新するなら `allowWrite` も）で開け、コマンドからの参照を `block-secret-read.sh` の列挙に足して塞ぐ。ファイルツールからは、作業ディレクトリの外なので `blockReadsOutsideWorkingDirectories` が閉じる。認証情報を渡す環境変数は `credentials.envVars` で閉じ、sandbox の中のツールはトークンキャッシュで認証させる
- `excludedCommands` のコマンドは sandbox の外で動き、sandbox の読取制限も `credentials` も効かない。除外は sandbox 内で動かないもの（設定を `credentials` で閉じた `gh` を含む）だけを、サブコマンドの単位で足す（`git` はネットワークや認証を使うサブコマンドだけ）。送信先の制限を迂回する経路になるもの（`az *`）は除外しない。除外を変えたら、`block-piped-excluded.sh` の列挙も合わせる
- `allowRead` には、ツールが Bash から読む場所を足す（`~/.claude/skills/` の symlink 先、`mise.toml` の `[dotfiles]` の配置先と `[bootstrap.repos]` の clone 先、nvim のプラグインの置き場所）。減らしたら `mise run lint` を通す。設定を読めなくなったツールは、エラーを出さずに既定値で動くことが多い
- 送信先（`network.allowedDomains`）は、sandbox の中で動くツールが通信する相手だけを許可する（`az` が使う Azure DevOps と Entra ID）。`excludedCommands` のコマンド（`gh`・git のネットワーク系）は sandbox の外で動くので、その通信先は足さない。`WebFetch` の allow で合流する docs のドメインは、上の `WebFetch` の基準で決める
- `sandbox.network.strictAllowlist` を、情報流出を防ぐ仕組みとしては数えない。制御するのは送信先だけで、許可した送信先の中にも流出の経路が残る

## hook の基準

- hook は、`permissions` のパターンが取りこぼす形を拾うためにある。そのため `matcher` は tool 名だけにし、同じパターン構文で絞り込む `if` フィルタを付けない。コマンドの分解はスクリプト側で行う
- `command` にはスクリプトのパスを直接書かず、スクリプトが無いときは `exit 2` で止める形で包む。直接書くと、改名・削除やリンクの欠落でスクリプトが無くなったときに、ガードが黙って外れる。包む形は `-x` で存在を確かめるので、スクリプトには実行ビットを付ける
- main / master への push は 4 つの層で止める: `permissions.ask`（素直な形）、`block-main-push.sh`（refspec などの形）、git の `pre-push` hook（`core.hooksPath` で全リポジトリに効き、Claude Code の外の push も止める）、`bin/repo setup` が入れる GitHub の ruleset（hook を飛ばした push も止める）

## worktree の基準

- worktree で走る subagent は、親の作業中の状態から始める（`worktree.baseRef: "head"`）
- agent の checkout に見える範囲を広げない。gitignore されたファイルを複製する `.worktreeinclude` は使わない
- worktree で走る agent に settings・hook を変える作業を任せない。`denyWrite` が指すのは本体の `claude/` だけで、worktree 内の複製（`.claude/worktrees/*/claude/`）は守られない
- worktree は Claude Code 自身の機能で作る。Bash から作ると checkout が失敗する（「決定と理由」の `.zshrc` の項）

## 置き場所

- 複数のリポジトリで打つコマンドの許可は `claude/settings.json` に、このリポジトリでしか打たないもの（`mise bootstrap`・`mise run sync|update`）は `.claude/settings.json` に置く。sandbox の `allowRead` / `allowWrite` は、`blockReadsOutsideWorkingDirectories` の下ではリポジトリ側に書いても効かないので、このリポジトリでしか使わない場所も `claude/settings.json` に置く
- `autoMode` は `claude/settings.json` に置く。classifier はプロジェクト設定の `autoMode` を読まない
- `claude/settings.json` は public repo にある。仕事用のインフラ情報（組織名・内部ホスト名）は `autoMode.environment` に書かず、追跡外の managed settings に置く
- `claude/settings.json` は CLI の版が揃わない複数の端末で共有する。スキーマが拒む値を含む設定ファイルは丸ごと使われないので、全端末の CLI が受け付ける形で書く。例: `attribution` は `false`（v2.1.281 で追加）ではなく、オブジェクト形式で `commit` / `pr` を空にする

## 決定と理由

- sandbox は symlink を解決した後の実体パスで判定する。読取を許可した場所に置いた symlink からでも、`denyRead` の下は読めない（v2.1.280）。そのため deny と `credentials.files` は実体パスで書く。`~/.config/gh`（このリポジトリへの symlink）経由の表記だけでは効かない。symlink でない環境のために、`~/.config/...` の表記も併記する
- `allowRead` に書いたパス自体が symlink だと、許可されるのは解決後の実体パスだけで、symlink のパスはホームの読取拒否に残る。読取を開けていない場所に置いた symlink（`~/.zshenv`）も、先が作業ディレクトリでも読めない（v2.1.288）。ツールは `~/.config/...` の経路で設定を開くので、`~/.config` は実ディレクトリにし、`[dotfiles]` で中身をエントリごとに symlink にする。許可したディレクトリの中にある symlink は、その先も許可されていれば読める
- sandbox は、作業ディレクトリの下にある `.zshrc` への書込を深さに関係なく拒否する（v2.1.280）。このリポジトリは `.config/zsh/.zshrc` を追跡しているので、Bash から worktree を作ると checkout の途中で失敗する
- `herdr` は sandbox 内で動かない（`herdr status` が `Operation not permitted` で失敗する）（v2.1.280）。Claude Code の外のターミナルで実行する
- `Read` deny の `*.pem` は `~/` の下に限る。`//**/*.pem` にすると sandbox の読取制限に合流して OS の CA バンドル（`/etc/ssl/cert.pem`）も塞ぎ、`allowedDomains` で許可した送信先にも sandbox 内の curl・git が TLS で接続できない（v2.1.288）。ホームの外の `.pem` は CA バンドルが主で、鍵はホームの下に置く前提
- ユーザー設定に `sandbox.filesystem.denyRead: ["~/"]` を置かない。`blockReadsOutsideWorkingDirectories` と併用すると、sandbox が作業ディレクトリを開け直さず、Bash から作業中のリポジトリを読めなくなる。ホームは block 自体が閉じる（v2.1.288）
- リポジトリ側の `permissions.additionalDirectories` は、`blockReadsOutsideWorkingDirectories` の下ではファイルツールにも sandbox にも効かない（v2.1.288、anthropics/claude-code#92582）。リポジトリ専用の場所もユーザー設定の `allowRead` に置き、後で実行されるプラグインの置き場所（nvim・zsh）には `allowWrite` を開けない
- `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` は使わない。有効にすると `defaultMode: "auto"` が効かず、セッションが manual mode で始まる（Shift+Tab で auto には切り替えられる）（v2.1.280）
