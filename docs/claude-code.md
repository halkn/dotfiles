# Claude Code 設定の設計

`claude/settings.json`（全リポジトリ共通）と `.claude/settings.json`（このリポジトリ専用）は JSON でコメントを書けないため、設定の理由はこの doc が持つ。各 hook の理由は `claude/hooks/*.sh` の冒頭コメントにある。

`claude/` の中身は `~/.claude/` にリンクされ、全てのプロジェクトの Claude Code に効く。全プロジェクト共通の指示は `claude/CLAUDE.md` に、このリポジトリ専用の指示は `AGENTS.md` に書く。

`~/.claude/CLAUDE.md` はローカルの Claude Code にだけ読まれ、クラウドには届かない。claude.ai の preferences は claude.ai のチャットとクラウドの Claude Code に読まれ、ローカルには読まれない。どの場所でも同じ指示が効くように、`claude/CLAUDE.md` の「ローカル環境」節より前を preferences に手で写す。

- 正本は `claude/CLAUDE.md`。preferences だけを直さない。リポジトリから preferences を読めないので、ずれを検知できない
- 「ローカル環境」節には、ローカルの `settings.json`（sandbox・`blockReadsOutsideWorkingDirectories`）を前提にする指示だけを置く。クラウドには別のハーネスの規則があるので、届かなくてよい
- 節より前に、特定の場所だけに当てる指示（「claude.ai のチャットでは」など）を置かない。置くなら読み手を限定して書く
- クラウドに `~/.claude/CLAUDE.md` を setup script で配る方法は採らない。setup script の結果は環境のキャッシュに残り、直した内容がすぐには届かない。環境ごとに設定が要る

好みの設定（表示・言語・エディタ操作・output style・statusline・プラグインの選択）は対象外。既定値と同じ値は書かない。前提は macOS（Seatbelt）で、WSL（bubblewrap）には当てはめない。

## 使い方の原則

- 作業の起点は、Claude Code を起動したリポジトリ。読取は `permissions.blockReadsOutsideWorkingDirectories` でそのリポジトリに限る。ファイルツールはその外を読まず、sandbox もホームを閉じてそのリポジトリを開け直すので、リポジトリごとに `allowRead: ["./"]` を書かない。セッション中に作業ディレクトリを動かさないため、`CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` で Bash コマンドごとに起点へ戻す。git のリモートを作業ディレクトリから解決する hook も、この前提に立つ
- ガードは、失敗やモードの切替で黙って外れないようにする。sandbox を起動できないときの素通り（`sandbox.failIfUnavailable`）、sandbox の外での再実行（`sandbox.allowUnsandboxedCommands`）、ask を飛ばすモード（`permissions.disableBypassPermissionsMode`）、hook スクリプトの欠落と異常終了（「hook の基準」）を閉じる
- セッションと外をつなぐ経路は、このリポジトリで管理しているものだけにする。外からセッションを操作・指示できる入口（Remote Control、claude.ai から同期される skill とプラグイン、Artifact へのコメント）と、セッションの内容を外へ出す経路（claude.ai の connector）は開けない。Anthropic のサーバーを経由して送り先を人が選ぶ経路（他のマシンや cloud のセッションへの `SendMessage`、Artifact）は、開けても人の承認を挟む（`isolatePeerMachines`、`permissions.ask` の `Artifact*`）
- CLI の認証（`gh auth login`・`az login`）は、Claude Code の外のターミナルで行う。Claude Code は、認証済みのトークンキャッシュを使うだけにする
- Claude Code 本体の更新は `mise run update` に一本化し、自動更新は止める。プラグインの更新は Claude Code に任せる。その代わり、skill を読み込むだけでコマンドが実行される inline shell（`` !`cmd` ``）は止める（`disableSkillShellExecution`）。更新で中身が変わっても、人の目を通らずに実行されるものが増えないようにする。自作の skill も inline shell を使わず、要る情報は skill の手順で Bash から取らせる
- Claude Code が作った commit・PR もユーザーの成果物として扱い、Claude Code の署名とセッションへのリンク（`attribution`）を付けない

## 層の使い分け

既定の permission mode は auto にする（`permissions.defaultMode`）。人の確認は ask に明示した操作だけにし、残りは classifier に任せる。

| 層 | 性質 | 置くもの |
| --- | --- | --- |
| CLAUDE.md / AGENTS.md | 強制力の無い context | 規約・判断基準 |
| `permissions` / hook | コマンド文字列の照合なので、書き方を変えればすり抜けられる。ask は auto モードでも classifier より先に効く | sandbox で表せないもの（取り返しのつかない外向きの操作の確認）と、二次防御 |
| auto モードの classifier（`autoMode`） | 文脈で判断するが、確実ではない | コマンド文字列で表せない境界（SQL の中身、どのリポジトリの文脈か） |
| `sandbox` | OS が強制する唯一の境界。ただし効くのは Bash だけ | 能力の制限（ファイルの読み書き・送信先） |
| git の `pre-push` hook | 実際に更新される ref を見るので、コマンドの書き方に左右されない | リモートの ref を消す・書き換える push の拒否 |
| GitHub の ruleset | サーバーが強制する | main の最終保証 |

- 確実に止めたい読取・書込は、Bash（sandbox）と Read / Edit / Write tool（`permissions`）の両方の経路を塞ぐ。`Read` deny と `Edit` deny は sandbox の読取・書込の制限にも合流するので、両方に効く 1 箇所に書き、`denyRead` / `denyWrite` に重ねない。どこに置かれても閉じたい認証情報のファイル名（`.env`・鍵）は `Read` deny に、ホーム全体は `blockReadsOutsideWorkingDirectories` に、鍵の置き場所（`~/.ssh`・`~/.gnupg`）と `.config/gh` は `Edit` deny に置く
- `autoMode` に足すルールは、ユーザーが対象を名指しして指示すれば通してよいもの（Snowflake の破壊的 DDL）を `soft_deny` に、指示があっても越えない境界（個人と仕事の間の転送）を `hard_deny` に置く。既定ルール（`claude auto-mode defaults`）が既に覆う範囲は書かず、差分だけを書く。`environment` には環境の事実だけを書き、ルールと同じ禁止を繰り返さない
- auto モードでは、全ての shell コマンドを classifier に通す（`autoMode.classifyAllShell`）。allow のパターンは、想定していない引数や script のパスまで通すため。`permissions.allow` の Bash ルールは他のモードに切り替えたときの予備になるので、確認なしで通っても安全な read-only の形だけを、サブコマンドまで明示して書く。組込みの read-only コマンドは全モードで確認なしに通るので、allow に書かない
- `sandbox.autoAllowBashIfSandboxed` は `true` にしない。`true` は、server の審査が無いセッションと他のモードで、sandbox 内のコマンドを確認も classifier も通さずに走らせる。sandbox は作業ディレクトリの中の破壊的な書込や、classifier が文脈で止める操作（`soft_deny`）を閉じないので、モードやセッションの種類で審査が黙って外れる

## CLAUDE.md の基準

`claude/CLAUDE.md` は全セッションで読まれ、行が増えるほど個々の規則が守られにくくなる。そのため、迷ったときに結論を変える判断基準だけを置く。

- 置くもの: ユーザーの好みのうち既定と違うもの、ガードが事前に教えない環境の罠、ハーネスの既定（システムプロンプト・ツールの説明）から意図して外れる点。外れる点は、外れることと理由を書く。書かないと既定が採られるか、どちらが採られるか不定になる
- 置かないもの: システムプロンプトやツールの説明が既に言うこと、hook・`pre-push` が拒否のメッセージで教えること（拒否は実行前に起き、次の呼び出しで直る）、手順（skill へ）、理由（この doc へ）、実測（commit へ）
- 強調（太字・IMPORTANT）は使わない。規則には、例外を判断できる短い理由を添える
- 見直すのは、モデルや Claude Code を更新したとき（`/doctor prompt-audit`）と、同じ失敗が繰り返されたとき。足すのは繰り返された失敗に対する 1 行だけにする。消した規則は、transcript で同じ失敗が増えていないかを確かめる

## ガードを足す・消すときの基準

- sandbox・`permissions`・auto モードの classifier という標準機能で代わりが効かないことを、先に示す
- 防ぐ対象は、道具（インタプリタ名・読取コマンド名）ではなく、守る資産（認証情報のパス・環境変数名・push 先ブランチ）の側で列挙する。道具は代わりがいくらでもあるが、資産の集合は閉じている
- deny に置くのは、取り返しがつかず、正当な用途もほぼ無いものだけ（権限の昇格、ローカルの復旧手段を消す操作、専用のサブコマンドを迂回する汎用の書込口、proxy を通らない生のソケット、ガードを飛ばす口、トークンの表示）。破壊的でも正当な用途がある操作は ask に置く。引数の書き方が開いていてパターンで捉えきれない操作（`git push` のオプション）は、作用を見る層（`pre-push`）で拒否し、必要なら人が Claude Code の外で行う
- ガードの照合そのものを外せる操作（`git config *alias.*`・`gh alias set`）は ask に置く。alias を作ると、以降のコマンドが permissions のパターンにも hook の照合にも当たらなくなる
- classifier の既定ルールが名指ししている操作は、原則として permissions に重ねない。重ねると、ユーザーが明示的に指示した操作にまで確認が出る。指示した後でも人が毎回確かめたい操作（未コミットの変更を捨てる・ブランチや worktree の削除・ツールの uninstall・PR の merge とリポジトリのガードの変更）だけは、あえて ask に重ねる
- sandbox が制御している書込先・送信先と、git で戻せる変更（lockfile・依存）は deny に置かない
- 入口が閉じている操作（`mise run sync|update`）は完全一致で ask に列挙する。引数の形が開いている操作（`mise bootstrap`）は両端だけを固定し（他ホストへの作用は deny、`--force-dotfiles`・`--yes` を先頭に置いた形は ask、`status`・`plan`・`--dry-run` は allow）、残りは classifier に任せる
- `WebFetch` の allow は書かない。auto モードでは allow が無くても通り、残る効果は確認を出すモード向けと sandbox の送信先への暗黙の合流だけになる。docs を原文で読む経路は `network.allowedDomains` で明示的に開ける
- パターンは、実際に打たれる形を確かめてから書く。オプションは `--opt=value` の形も併記する
- subagent に委譲するかどうかはハーネスの既定に任せ、CLAUDE.md にも設定の上限（同時実行数・入れ子の深さ）にも置かない

## sandbox の基準

- 読取は既定で閉じ、ツールが必要とする場所だけを開ける（`blockReadsOutsideWorkingDirectories` と `allowRead`）。丸ごと開けて例外を列挙する形は取らない。列挙から漏れたものが開いたままになる
- 書込を開けるのは、ツールが自分の状態を書く場所だけ。他のプロセスが後で読み込んで実行する場所には開けない（`~/.azure` の拡張と設定は `denyWrite` で塞ぐ、`~/.cache` はツール単位で開ける）。skill の出力は作業ディレクトリ（一時的なものは scratchpad）に置き、ホームに出力先を開けない。書込を開けた場所は `allowRead` にも書く（block の下では `allowWrite` は読取を開けない）
- Claude Code が読み込む・実行するファイル（`claude/` 全体）は、組込みの保護に頼らず `denyWrite` と `Edit` の ask で塞ぐ。組込みの保護が覆う範囲は版で変わり、symlink の先まで届くとは限らない。リポジトリ側の `.claude/settings*.json` も同じく ask に入れる。ask は classifier より先に効くので、自己改変の拒否ではなく人の確認になる
- 各ツールの設定を守る主な境界は、他のリポジトリのセッションから書けないこと。このリポジトリでの編集は意図したもので `git status` に出るので、`.config/` の下と、sandbox の外のシェルや mise が実行するもの（`.zshenv`・`bin/`・`mise.toml`・`mise-tasks/`）は確認なしで書かせる
- その例外として、次のものは `denyWrite` と `Edit` の ask で塞ぐ。塞ぐ単位はディレクトリにし、後から足されたファイルも覆う
  - Claude 自身の次のコマンドが、人の操作を待たずに sandbox の外で実行するもの: `core.hooksPath` の hook と git の config を持つ `.config/git`。書き換えた直後の `git push` で実行され、人がレビューする間が無い
  - gitignore されていて、書き換えても `git status` に出ないもの: herdr のプラグインのインストール先 `.config/herdr/plugins/github-installations` と、その build の入力 `.config/herdr/plugins/github`。追跡しているプラグインの設定 `.config/herdr/plugins/config` は塞がない
  - 認証情報を持つ `.config/gh` は、塞ぐのではなく `Read` / `Edit` deny にする
- 副作用として、塞いだパスを変える `git switch` / `git merge` は sandbox 内で失敗する。formatter も塞いだパスを書き換えられないので、`mise run fmt` は差分のあるときだけ書く形にする
- ツールの data / state ディレクトリ（`~/.local/share`・`~/.local/state` の下）は読取だけを開ける。PATH に載るバイナリと mise の trust があり、書ければ外のシェルが、コマンド名を打つだけ・ディレクトリに入るだけで差し替えたものを実行する。副作用として、インストール系の操作と `mise trust` は sandbox 内で失敗するので、ユーザーに `!` で頼む
- キャッシュは、sandbox の中のツールが自分で中身を作るものだけ書込を開ける。外で埋めた中身を読むだけのもの（GOMODCACHE、`CARGO_HOME` の registry）は読取だけにする。外のシェルの PATH に直接効くキャッシュ（mise の `bin_paths`）は、`env` の `MISE_CACHE_DIR` で sandbox 用に分ける。分けられない共有キャッシュ（GOCACHE・uv・bun）は外で実行されうる経路として受け入れ、それ以上隔離するなら Claude Code をコンテナなどで動かす
- deny と `allowRead` は symlink を解決した実体パスで書く。sandbox は実体パスで判定する。そのため `~/.config` は実ディレクトリにし、中身をエントリごとに symlink にする（`mise.toml` の `[dotfiles]`）。symlink 側のパスの rule は足さない
- 追跡されている公開設定は閉じない（`~/.config` は丸ごと開ける）。閉じるのは追跡外で認証情報を持つものだけで、`sandbox.credentials` に宣言する
- 認証情報の閉じ方は、それを使うツールが sandbox のどちら側で動くかで決まる。外で動くツール（`gh`）の認証情報は `sandbox.credentials` で閉じる。中で動くツール（`az`）の認証情報は、閉じるとツール自身も読めないので開け、コマンドからの参照を `block-secret-read.sh` の列挙に足して塞ぐ。このリポジトリにある実体（`.config/gh`）は作業ディレクトリの中なので、`Read` / `Edit` の deny で閉じる。認証情報を渡す環境変数は `credentials.envVars` で閉じ、中のツールはトークンキャッシュで認証させる
- `Read` deny の `*.pem` は `~/` の下に限る。全体にすると OS の CA バンドルも塞ぎ、sandbox 内の TLS 接続が全て失敗する
- `excludedCommands` のコマンドは sandbox の外で動き、読取制限も `credentials` も効かない。除外は sandbox 内で動かないもの（`gh`）と、git のネットワークや認証を使うサブコマンドだけを足す。送信先の制限を迂回する経路になるもの（`az *`）と、作業ツリーを書き換えるもの（`pull`・`submodule`）は除外しない。git を丸ごと除外しないのは、`-c`・alias・hook で任意のコマンドを外で動かせるため。除外は裸のコマンド（と `2>&1`）でだけ保たれる前提に立ち、それ以外の形は `block-piped-excluded.sh` が拒否する。除外を変えたら、その列挙も合わせる
- `allowRead` には、ツールが Bash から読む場所を足す（`[dotfiles]` の配置先、`[bootstrap.repos]` の clone 先、nvim のプラグインの置き場所）。リポジトリ側の `additionalDirectories` は block の下で効かないので、ユーザー設定に置く。減らしたら `mise run lint` を通す。設定を読めなくなったツールは、エラーを出さずに既定値で動くことが多い
- `~/.claude` は `allowRead` で開けない。Bash に要る部分は block が開け直すので、開け直されないものだけを足す。残りにはセッションの transcript が含まれ、要るときは `/add-dir` で足す
- `~/.claude/skills/` の skill は、別のリポジトリへの symlink にせず、`gh skill install --agent claude-code --scope user` で実体を置く。symlink の先は作業ディレクトリの外として扱われ、読むたびに確認になる。自作の skill の変更は、skill のリポジトリに push してから `gh skill update` で反映する
- 送信先（`network.allowedDomains`）は、sandbox の中で動くツールが通信する相手（`az` の Azure DevOps と Entra ID）と、仕様を原文で確かめる頻度が高い公式 docs だけを許可する。docs でも、誰でも読める投稿を匿名で作れる API を同じホストに持つものは足さない。`excludedCommands` のコマンドの通信先は足さない
- `sandbox.network.strictAllowlist` を、情報流出を防ぐ仕組みとしては数えない。制御するのは送信先だけで、許可した送信先の中にも流出の経路が残る

## hook の基準

- hook は、`permissions` のパターンが取りこぼす形を拾うためにある。もう 1 つの用途は、安全チェックの確認や sandbox 内の失敗になると分かっている形を、代わりの形を添えて先に拒否すること（`block-prompting-shapes.sh`、`block-piped-excluded.sh`）。拒否のメッセージが代わりを教えるので、その形は CLAUDE.md に書かない。拒否するのは、機械で判定でき、代わりの形が決まるものだけにする。正当な用途と区別できない形（`~/.claude` の下の読取など）まで拒否すると、承認で通す道が無くなるので、CLAUDE.md に置く。`matcher` は tool 名だけにし、`if` フィルタを付けない。コマンドの分解はスクリプト側で行う
- `command` にはスクリプトのパスを直接書かず、スクリプトが無いときは `exit 2` で止める形で包む。直接書くと、スクリプトが無くなったときにガードが黙って外れる。包む形は `-x` で存在を確かめるので、スクリプトには実行ビットを付ける
- ガードの hook には `onFailure: "block"` を付ける。付けないと、異常終了やタイムアウトで tool の呼び出しが通る。付けると判定できない入力でも拒否になるので、判定が通すべき入力は `exit 0` まで届くようにする
- `claude/hooks/` の hook と git の `pre-push` の判定を変えたら、テストを足す。置き場所は [shell.md](shell.md) の「テスト」に従う

## git / gh の基準

- Claude が確認なしで進める範囲は、作業ブランチの作成から、そのブランチへの commit・push と PR の作成まで。classifier の既定ルールが通すので、allow も ask も足さない
- CLAUDE.md の Git の規則（自分の作業ブランチだけに push する・merge やガードの変更は名指しで指示されたときだけ）は、classifier の既定ルールと重なっても残す。既定ルールは、どのブランチへの push も、人の承認後の merge も、Azure DevOps の操作も止めない
- リモートを壊さないことは、コマンドの書き方に左右されない層で守る: GitHub の ruleset（`bin/repo setup` が入れる）と、git の `pre-push` hook。`permissions` のパターンは git のオプションの省略形や結合を拾えないので、push の判定には使わない
- `pre-push` が Claude の push で拒否するものは、スクリプト冒頭のコメントにある。ruleset の無いリポジトリでは唯一の歯止めになる。Claude の push には解除の手段を持たせず、必要なら人が Claude Code の外のターミナルで行う
- Claude の git には、`env` の `GIT_CONFIG_*` で `core.hooksPath` を全体の hook の置き場所に固定する。リポジトリ側が hook を作業ツリー内に向けていても全体の `pre-push` が走り、sandbox 内から書き換えられる hook が外で実行されることもない。副作用として、リポジトリ固有の hook は Claude の git では走らない
- `pre-push` を外す経路を残さない。`--no-verify` は省略形も拾うよう deny する。git / gh の前に何かを置いた形と `&` で後ろに続けた形は、`block-piped-excluded.sh` が拒否する。除外が読み飛ばす wrapper は版で変わるので列挙せず、行頭が git / gh でない形を全て拒否する。引数に改行かバッククォートを含む形も除外から外れるので拒否し、本文はファイルで渡させる
- gh の書込のうち、main / master を変える操作（`gh pr merge`）とリポジトリのガードの変更（`gh repo edit|rename|archive|unarchive|sync`）は、素直な形に限り `permissions.ask` で確認する。ruleset は承認を求めないので、PR を作れる Claude は merge もできる。別の形（サブコマンドの前のフラグ、`gh api`）で同じことをする経路は classifier に任せ、hook で重ねない。Claude が素直な形を避けて打つのは意図的な回り込みに限られるので許容する
- トークンの表示と認証の変更（`gh auth`）、リポジトリの削除、`gh api` での ref の直接操作、拡張の導入は、素直な形を deny に置く。gh は sandbox の外で動き、`sandbox.credentials` が効かないため。すり抜ける形は classifier に任せる
- gh のガードは、Claude 専用のトークンではなく `permissions` と classifier で持つ。merge と ref の更新は push と同じ権限で動き、トークンでは分けられない。他人が書いた内容（公開リポジトリの issue や PR）を auto モードで扱う場面が増えたら、トークンで Administration を外すことを見直す
- Azure DevOps（`az repos`）の merge とブランチポリシーの変更は、CLAUDE.md の Git の規則だけで守る。問題が出たら、gh と同じく素直な形を ask に足す
- 人の gh のトークンにも、Claude の作業に要らない scope（`admin:public_key`・`workflow`）は付けない。git の通信は SSH で、gh のトークンを使わない
- git / gh のネットワーク系は、起動したリポジトリで単体のコマンドとして打つことを CLAUDE.md に置く。hook の拒否で直るが、繰り返されるため。対象は「ネットワーク系」とまとめずコマンドを名指しする（まとめると `gh` の読取が対象外と読まれる）。他のリポジトリの GitHub 操作は `gh -R` で行い、push はそのリポジトリで起動したセッションから行う

## worktree の基準

- worktree で走る subagent は、親の作業中の状態から始める（`worktree.baseRef: "head"`）
- agent の checkout に見える範囲を広げない。gitignore されたファイルを複製する `.worktreeinclude` は使わない
- worktree で走る agent に settings・hook を変える作業を任せない。`denyWrite` が指すのは本体の `claude/` だけで、worktree 内の複製は守られない
- worktree は Claude Code 自身の機能で作る。sandbox は作業ディレクトリの下の `.zshrc` への書込を拒否するので、Bash から作ると追跡している `.config/zsh/.zshrc` の checkout で失敗する

## 一時ファイルと確認

- auto モードで ask 以外に出る確認のほとんどは、`blockReadsOutsideWorkingDirectories` の安全チェック（作業ディレクトリの外のパスを書いた Bash と、sandbox の外で動く Bash のうち shell parser が追えないもの）で、allow でも hook の `allow` でも外せない。避け方は、判定できる形を `block-prompting-shapes.sh` で先に拒否し、判定できない形を CLAUDE.md に置く
- 一時ファイルはハーネスの指示どおり scratchpad に置き、ファイルツールで扱う。scratchpad と `$TMPDIR` は作業ディレクトリの外なので、Bash のコマンドにそのパスを書くと確認になる。Bash の出力はファイルに書かずパイプで絞る。例外は `gh` の `--body-file`・`-F` で、sandbox の外で読むので `$TMPDIR` ではなく scratchpad の絶対パスを渡す
- scratchpad が無いセッション（API キー・Bedrock など）では、作業ディレクトリの `.scratch/<テーマ>/` に置いて相対パスで渡す。並行するセッションと共有されるのでテーマで分け、使い終えたら消し、commit に含めない。自前の ignore しか読まないツールを使うリポジトリでは、その ignore に `.scratch/` を足す
- temp のルートを `additionalDirectories` に足す案は採らない。パスが OS と uid に依存し、全セッションの temp をファイルツールに開く

## 置き場所

- 複数のリポジトリで打つコマンドの許可は `claude/settings.json` に、このリポジトリでしか打たないものは `.claude/settings.json` に置く。sandbox の `allowRead` / `allowWrite` は、block の下ではリポジトリ側に書いても効かないので、このリポジトリでしか使わない場所も `claude/settings.json` に置く
- このリポジトリのファイルを塞ぐ `denyWrite` と `Edit` の ask は、`.claude/settings.json` に相対パスで書く。`claude/settings.json` には clone 先の絶対パスを書かない。例外は `.config/gh` の `Read` / `Edit` deny で、他のリポジトリのセッションからも `allowRead` の `.config` で実体を開けるので `claude/settings.json` に置く
- `autoMode` は `claude/settings.json` に置く。classifier はプロジェクト設定の `autoMode` を読まない
- `claude/settings.json` は public repo にある。仕事用のインフラ情報（組織名・内部ホスト名）は `autoMode.environment` に書かず、追跡外の managed settings に置く
- `claude/settings.json` は CLI の版が揃わない複数の端末で共有する。スキーマが拒む値を含む設定ファイルは丸ごと使われないので、新しい形が入っても、全端末の CLI が受け付ける形で書く（`attribution` は `false` ではなくオブジェクト形式）

## 決定と理由

- Artifact は `permissions.ask` で挟む。頼まれなくても公開され、ask だけが auto モードでも確認を出す。tool は版ごとに増えるので glob `Artifact*` で覆う。ask は tool 単位なので read・list・open にも確認が出る。公開するファイルに認証情報が含まれていないかは、この確認で人が見る
- Artifact へのコメントは `CLAUDE_CODE_ARTIFACT_COMMENTS=0` で止める。届いたコメントがセッションに渡り、外から指示できる入口になる
- 公開と同時にファイルを書き換える one-step update は `CLAUDE_CODE_ARTIFACT_PUBLISH_EDITS=0` で止める。Edit tool を通らず、`Edit` の ask と、塞いだパスを Edit / Write tool に寄せる規約を迂回する
- `herdr` は sandbox 内で動かないので、Claude Code の外のターミナルで実行する
- herdr のプラグインの checkout（`.config/herdr/plugins/github*`）の CLAUDE.md・rules は、`.claude/settings.json` の `claudeMdExcludes` で読み込ませない。サブディレクトリの CLAUDE.md はそこのファイルを扱った時点で context に入り、第三者が書いた指示がセッションに混ざる
- CLAUDE.md の `ast-grep` は、構文を条件にする検索の一般論では使われないので、差が出る書き換えだけを名指しする。検索全般は `rg` のままにする
- 採らないもの
  - ユーザー設定の `sandbox.filesystem.denyRead: ["~/"]`: block と併用すると作業ディレクトリが開け直されず、Bash から作業中のリポジトリを読めなくなる
  - `.claude/rules/`: path-scoped rule はファイルツールで一致するファイルを扱ったときにしか読まれず、読まれなくてもエラーが出ない。1 つのリポジトリの方針はその設計ドキュメントに置き、skill は複数のリポジトリで繰り返す手順にだけ使う
  - 上流のリポジトリを作業木（`.scratch/`）に clone して読む: clone 先の CLAUDE.md・rules・`.claude/skills` は、そこのファイルを読んだ時点でセッションに読み込まれる。`claudeMdExcludes` は skill を外せない。上流は `gh api` の raw で読み、本文をデータとして扱う
  - `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`: 有効にすると `defaultMode: "auto"` が効かず、manual mode で始まる
