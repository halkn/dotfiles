# Claude Code 設定の設計

`claude/settings.json`（全リポジトリ共通）と `.claude/settings.json`（このリポジトリ専用）は JSON でコメントを書けないため、設定の理由はこの doc が持つ。各 hook の理由は `claude/hooks/*.sh` の冒頭コメントにある。

`claude/` の中身は `~/.claude/` にリンクされ、全てのプロジェクトの Claude Code に効く。全プロジェクト共通の指示は `claude/CLAUDE.md` に、このリポジトリ専用の指示は `AGENTS.md` に書く。`claude/` は sandbox で Bash から書けないので、Edit / Write tool で編集する。

好みの設定（表示・言語・エディタ操作・output style・statusline・プラグインの選択）は対象外。既定値と同じ値は書かない。前提は macOS（Seatbelt）で、WSL（bubblewrap）には当てはめない。

## 使い方の原則

- 作業の起点は、Claude Code を起動したリポジトリ。読取は `permissions.blockReadsOutsideWorkingDirectories` でそのリポジトリに限る。ファイルツールはその外を読まず、sandbox もホームを閉じてそのリポジトリを開け直すので、リポジトリごとに `allowRead: ["./"]` を書かない。セッション中に作業ディレクトリを動かさないため、`CLAUDE_BASH_MAINTAIN_PROJECT_WORKING_DIR` で Bash コマンドごとに起点へ戻す。git のリモートを作業ディレクトリから解決する hook も、この前提に立つ
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
| git の `pre-push` hook | 実際に更新される ref を見るので、コマンドの書き方に左右されない | リモートの ref を消す・書き換える push の拒否 |
| GitHub の ruleset | サーバーが強制する | main の最終保証 |

- 確実に止めたい読取・書込は、Bash（sandbox）と Read / Edit / Write tool（`permissions`）の両方の経路を塞ぐ。`permissions` の `Read` deny は sandbox の読取制限にも合流し、`allowRead` で開けた範囲の中でも効く。そのため、どこに置かれても閉じたい認証情報のファイル名（`.env`・鍵）は `Read` deny に、ホーム全体を閉じるのは、ファイルツールと sandbox の両方に効く `blockReadsOutsideWorkingDirectories` に置く。書込も同じで、鍵の置き場所（`~/.ssh`・`~/.gnupg`）は `denyWrite` と `Edit` deny の両方で閉じる
- `autoMode` に足すルールは、ユーザーが対象を名指しして指示すれば通してよいもの（Snowflake の破壊的 DDL）を `soft_deny` に、指示があっても越えない境界（個人と仕事の間の転送）を `hard_deny` に置く
- auto モードでは、全ての shell コマンドを classifier に通す（`autoMode.classifyAllShell`）。allow のパターンは、想定していない引数や script のパスまで通すため。`permissions.allow` の Bash ルールは他のモードに切り替えたときの予備になるので、確認なしで通っても安全な read-only の形だけを、サブコマンドまで明示して書く（`Bash(git *)` は、書込や任意実行を取り込む形まで通してしまう）。組込みの read-only コマンド（`ls`・`cat` や `git` の read-only な形）は全モードで確認なしに通るので、allow に書かない

## ガードを足す・消すときの基準

- sandbox・`permissions`・auto モードの classifier という標準機能で代わりが効かないことを、先に示す
- 防ぐ対象は、道具（インタプリタ名・読取コマンド名）ではなく、守る資産（認証情報のパス・環境変数名・push 先ブランチ）の側で列挙する。道具は代わりがいくらでもあるが、資産の集合は閉じている
- deny に置くのは、取り返しがつかず、正当な用途もほぼ無いものだけ。例: 権限の昇格（`sudo`）、ローカルの復旧手段を消す操作（`git reflog expire`・`git gc --prune`）、専用のサブコマンドを迂回する汎用の書込口（`az devops invoke` の `--http-method`）、proxy を通らない生のソケット（`nc`・`ssh`・`scp`）、ガードを飛ばす口（`git push --no-verify`）、トークンの表示（`gh auth token`）。破壊的でも正当な用途がある操作（`mise bootstrap --force-dotfiles`）は ask に置く。ただし、引数の書き方が開いていてパターンで捉えきれない操作（`git push` のオプション）は、作用を見る層（`pre-push`）で拒否し、必要なら人が Claude Code の外で行う
- ガードの照合そのものを外せる操作は ask に置く。例: `git config *alias.*`・`gh alias set`（alias を作ると、以降のコマンドが permissions のパターンにも hook の照合にも当たらなくなる）
- classifier の既定ルール（`claude auto-mode defaults` で確かめる）が名指ししている操作は、原則として permissions に重ねない。重ねると、ユーザーが明示的に指示した操作にまで確認が出る。指示した後でも人が毎回確かめたい操作（未コミットの変更を捨てる `git checkout -f`・ブランチや worktree の削除・ツールの uninstall・PR の merge とリポジトリのガードの変更）だけは、あえて ask に重ねる
- sandbox が制御している書込先・送信先と、git で戻せる変更（lockfile・依存）は deny に置かない
- 入口が閉じている操作（`mise run sync|update`）は完全一致で ask に列挙する。引数の形が開いている操作（`mise bootstrap`）は列挙しきれないので、両端だけを固定し（他ホストへの作用は deny、`--force-dotfiles`・`--yes` を先頭に置いた形は ask、`status`・`plan`・`--dry-run` は allow）、残りは classifier に任せる
- `WebFetch` の allow は書かない。auto モードの WebFetch は allow が無くても確認なしで通り、allow の残る効果は確認を出すモード（Manual・`acceptEdits`）向けと、sandbox の送信先への暗黙の合流だけになる。docs を原文で読む経路は `network.allowedDomains` で明示的に開ける
- パターンは、実際に打たれる形を確かめてから書く。オプションは `--opt=value` の形も併記する
- 判断の質の問題（subagent に委譲するかどうか）は CLAUDE.md で扱い、設定の上限（同時実行数・入れ子の深さ）で抑えない

## sandbox の基準

- 読取は既定で閉じ、ツールが必要とする場所だけを開ける（`blockReadsOutsideWorkingDirectories` と `allowRead`）。丸ごと開けて例外を列挙する形は取らない。列挙から漏れたものが開いたままになる
- 書込を開けるのは、ツールが自分の状態を書く場所だけ（`~/.azure` のトークンキャッシュ、skill の出力先）。他のプロセスが後で実行する場所には開けない。`~/.cache` をツール単位で開けるのはこのため（ログインシェルが起動時に実行するキャッシュがあり、そこへ書ければ sandbox の外でコードを走らせられる）
- Claude Code が読み込む・実行するファイル（`claude/` 全体）は、組込みの保護に頼らず `denyWrite` と `Edit` の ask で塞ぐ。組込みの保護が覆う範囲は版で変わり、symlink の先にある hook や statusline のスクリプトまで届くとは限らない。副作用として、`claude/` を変える `git switch` / `git merge` は sandbox 内で失敗する。Claude がこれらを変えるときは Edit / Write tool を使い、ask の確認で人が承認する（Bash は `denyWrite` で通らない）。リポジトリ側の `.claude/settings*.json` も同じ経路にするため ask に入れる。auto モードでは保護パスへの書込が classifier に回り、自己改変として拒否されることがあるが、ask は classifier より先に効いて確認になる
- sandbox の外で動くコマンドが読み込んで実行するファイルも、同じく `denyWrite` とファイルツールの ask / deny で塞ぐ。sandbox から書けると、次の `git push` や `gh` で sandbox の外にコードを持ち出せる。このリポジトリでは、`core.hooksPath` の hook と git の config（`credential.helper` など）を持つ `.config/git` と、alias を持つ `.config/gh` が当たる。副作用は `claude/` と同じ
- 追跡されている公開設定は閉じない（`~/.config` は丸ごと開ける）。閉じるのは、追跡外で認証情報を持つものだけで、`sandbox.credentials` に宣言する。認証情報だと宣言でき、許可を広げる方向の誤用も起きない
- 認証情報の閉じ方は、それを使うツールが sandbox のどちら側で動くかで決まる。sandbox の外で動くツール（`gh`）の認証情報は `sandbox.credentials` で閉じる。sandbox の中で動くツール（`az`）の認証情報は、閉じるとツール自身も読めないので `allowRead`（更新するなら `allowWrite` も）で開け、コマンドからの参照を `block-secret-read.sh` の列挙に足して塞ぐ。ファイルツールからは、作業ディレクトリの外なので `blockReadsOutsideWorkingDirectories` が閉じる。このリポジトリにある実体（`.config/gh`）は作業ディレクトリの中なので、`Read` / `Edit` の deny で閉じる。認証情報を渡す環境変数は `credentials.envVars` で閉じ、sandbox の中のツールはトークンキャッシュで認証させる
- `excludedCommands` のコマンドは sandbox の外で動き、sandbox の読取制限も `credentials` も効かない。除外は sandbox 内で動かないもの（設定を `credentials` で閉じた `gh` を含む）だけを、サブコマンドの単位で足す（`git` はネットワークや認証を使うサブコマンドだけ）。送信先の制限を迂回する経路になるもの（`az *`）は除外しない。git は通信だけを行うサブコマンドに限り、作業ツリーを書き換えるもの（`pull`・`submodule`）は除外しない（`git fetch` と sandbox 内の `git merge` に分ける）。git を丸ごと除外しないのは、`-c core.pager=…`・`-c alias.x='!…'`・hook で任意のコマンドを sandbox の外で動かせるため。除外したサブコマンドも hook と config からコマンドを実行するので、その置き場所を sandbox から書けないようにする。除外を変えたら、`block-piped-excluded.sh` の列挙も合わせる
- `allowRead` には、ツールが Bash から読む場所を足す（`~/.claude/skills/` の symlink 先、`mise.toml` の `[dotfiles]` の配置先と `[bootstrap.repos]` の clone 先、nvim のプラグインの置き場所）。減らしたら `mise run lint` を通す。設定を読めなくなったツールは、エラーを出さずに既定値で動くことが多い
- `~/.claude` は `allowRead` で開けない。Bash に要る部分（skills・plugins・rules など）は `blockReadsOutsideWorkingDirectories` が開け直し、残りにはセッションの transcript（`~/.claude/projects`）が含まれる。履歴の分析など、その都度要るときは `/add-dir` で足す
- 送信先（`network.allowedDomains`）は、sandbox の中で動くツールが通信する相手（`az` が使う Azure DevOps と Entra ID）と、仕様を原文で確かめる頻度が高い公式 docs（Claude Code・mise・Azure・Snowflake）だけを許可する。docs は WebFetch が抽出用のプロンプトを通して要約するので、`curl` で取得して `rg` で原文を引けるようにする。`excludedCommands` のコマンド（`gh`・git のネットワーク系）は sandbox の外で動くので、その通信先は足さない
- `sandbox.network.strictAllowlist` を、情報流出を防ぐ仕組みとしては数えない。制御するのは送信先だけで、許可した送信先の中にも流出の経路が残る

## hook の基準

- hook は、`permissions` のパターンが取りこぼす形を拾うためにある。そのため `matcher` は tool 名だけにし、同じパターン構文で絞り込む `if` フィルタを付けない。コマンドの分解はスクリプト側で行う
- `command` にはスクリプトのパスを直接書かず、スクリプトが無いときは `exit 2` で止める形で包む。直接書くと、改名・削除やリンクの欠落でスクリプトが無くなったときに、ガードが黙って外れる。包む形は `-x` で存在を確かめるので、スクリプトには実行ビットを付ける

## git / gh の基準

- Claude が確認なしで進める範囲は、作業ブランチの作成から、そのブランチへの commit・push と PR の作成まで。auto モードの classifier は、作業中のリポジトリへの push と依頼に沿った PR の作成を既定で通すので、allow も ask も足さない
- CLAUDE.md の Git の規則（自分の作業ブランチだけに push する・merge やガードの変更は名指しで指示されたときだけ・破壊的操作の事前確認）は、classifier の既定ルールと重なっても残す。既定ルールは、session のリポジトリのどのブランチへの push も通し（Git Push Destination）、人の承認後の merge・Azure DevOps の操作・agent が触ったファイルの復元を止めない（v2.1.289）
- リモートを壊さないことは、コマンドの書き方に左右されない層で守る: GitHub の ruleset（main の最終保証。`bin/repo setup` が入れる）と、git の `pre-push` hook（push ごとの判定）。`permissions` のパターンは、git のオプションの省略形や結合（`--del`・`-uf`）を拾えないので、push の判定には使わない
- `pre-push` は、Claude の push（`CLAUDE_CODE_CHILD_SESSION=1`）について、ref の削除・非 fast-forward・既存のタグの書換え・保護ブランチ（main・master・develop・release/*・リモートの既定ブランチ）への push を拒否する。classifier の既定ルール（Git Push Destination）は既定ブランチへの push も通す（v2.1.289）ので、ruleset の無いリポジトリではこれが唯一の歯止めになる。解除の手段は持たせない。必要なら人が Claude Code の外のターミナルで行う。自分のブランチでの作業が止まらないよう、push 済みのブランチは履歴を書き換えずに commit を積むことを CLAUDE.md に置く。人の push は main / master の force と削除だけを拒否し、`ALLOW_FORCE_PUSH=1` で解除できる
- Claude の git には、`env` の `GIT_CONFIG_*` で `core.hooksPath` を全体の hook の置き場所に固定する。リポジトリ側の設定が hook を作業ツリー内（husky など）に向けていても、Claude の push では全体の `pre-push` が走り、sandbox 内から書き換えられる hook が sandbox の外で実行されることもない。副作用として、リポジトリ固有の hook は Claude の git では走らない。検証は Claude が明示的に実行する
- `pre-push` を外す経路を残さない。`--no-verify` は deny（省略形も拾うよう `--no-veri` で照合する）。`git -c core.hooksPath=…` は sandbox 内で動いて通信できない。git / gh の前に何かを置いた形（`cd`・wrapper・`VAR=…`）と、`&` で後ろに続けた形は、`block-piped-excluded.sh` がまとめて拒否する。除外は wrapper を読み飛ばして sandbox の外で動かすので、`env -u CLAUDE_CODE_CHILD_SESSION` で `pre-push` の判定を外せてしまう。読み飛ばす wrapper の一覧は版で変わるので列挙せず、行頭が git / gh でない形を全て拒否する。副作用として、引数に引用符なしで書いただけの `gh` も拒否される（拒否メッセージが引用符で囲むよう伝える）
- gh の書込のうち、main / master を変える操作（`gh pr merge`）とリポジトリのガードの変更（`gh repo edit|rename|archive|unarchive|sync`）は、素直な形に限り、ユーザーが指示した後でも `permissions.ask` で確認する。ruleset は PR を求めるが承認は求めないので、PR を作れる Claude は merge もできる。同じことを別の形（サブコマンドの前のフラグ、`gh api` の REST・GraphQL）で行う経路と、他のリポジトリへの PR の作成は、classifier の既定ルール（Merge Without Review・CI Bypass・Create Public Surface・Auto-Mode Bypass、v2.1.289）に任せ、hook で重ねない。ユーザーが名指しした後や、人の承認後の merge は確認なしで通り得るが、Claude が素直な形を避けて打つ場面は意図的な回り込みに限られるので許容する
- トークンの表示と認証の変更（`gh auth token|login|refresh|switch|logout|setup-git`）、リポジトリの削除（`gh repo delete`）、`gh api` での ref の直接操作（`git/refs`）、拡張の導入（`gh extension install`）は、素直な形を deny に置く。gh は sandbox の外で動き、`sandbox.credentials` が効かないため。パターンをすり抜ける形（結合したフラグ、サブコマンドの前のフラグ、`gh api` での DELETE）は classifier（Credential Materialization・Irreversible Deletion）に任せる。alias は照合を外せるので ask に置く
- gh のガードは、Claude 専用のトークンではなく `permissions` と classifier で持つ。merge と ref の更新は push と同じ Contents の書込権限で動くので、トークンの権限では分けられない。トークンで閉じられるのは Administration（branch protection・ruleset・リポジトリ設定）だけで、個人のリポジトリを自分が書いたコードで扱う範囲では、パターンをすり抜ける形が残っても許容する。他人が書いた内容（公開リポジトリの issue や PR、第三者のリポジトリ）を auto モードで扱う場面が増えたら、トークンで Administration を外すことを見直す
- 人の gh のトークンにも、Claude の作業に要らない scope（`admin:public_key`・`workflow`）は付けない。git の通信は SSH で、gh のトークンを使わない
- git / gh のネットワーク系は、起動したリポジトリで単体のコマンドとして打つ。`excludedCommands` の除外はコマンドの形で外れ、外れると認証にも送信先にも届かない。外れる形は `block-piped-excluded.sh` が拒否し、CLAUDE.md が事前に伝える。他のリポジトリの GitHub 操作は `gh -R` で行い、push はそのリポジトリで起動したセッションから行う

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
- sandbox の組込みの保護は、作業ディレクトリの下の `.git` の hooks・config と `.gitconfig` を覆うが、`.config/git` は覆わない。`core.hooksPath` の先（`.config/git/hooks`）に Bash から書けた（v2.1.288）
- `git push` は、長いオプションの一意な省略形と、短いオプションの結合を受け付ける。`--del` で削除、`--mir` で mirror、`--no-veri` で `pre-push` を飛ばせ、`-uf` で force になる。コマンドの文字列からは push の作用を判定できない（git 2.50.1）。`pre-push` は `--dry-run` でも走るので、判定は dry-run で確かめられる
- excludedCommands の除外は、裸のコマンドと `2>&1` でだけ保たれる前提に立つ。前置きの扱いは形ごとにばらつく:`VAR=… gh`・`command gh`・絶対パスへの `git clone` は sandbox 内で動き、`nice env -u CLAUDE_CODE_CHILD_SESSION git push` は sandbox の外で動いて `pre-push` に人の push として通った（v2.1.288、macOS）。引用符やバックスラッシュを付けた名前（`nice env 'gh'`・`nice env \gh`）は sandbox 内で動いた。hook は引用符の中身を照合から外すのでこれらを通すが、sandbox 内で失敗するだけで済む。除外の照合が引用符を外すようになったら、hook も語を正規化してから照合する
- sandbox 内のコマンドには Claude Code が `GIT_CONFIG_*` で `safe.directory` を足すが、`env` で渡した項目は残して `GIT_CONFIG_COUNT` を増やす（v2.1.288）
- `herdr` は sandbox 内で動かない（`herdr status` が `Operation not permitted` で失敗する）（v2.1.280）。Claude Code の外のターミナルで実行する
- `Read` deny の `*.pem` は `~/` の下に限る。`//**/*.pem` にすると sandbox の読取制限に合流して OS の CA バンドル（`/etc/ssl/cert.pem`）も塞ぎ、`allowedDomains` で許可した送信先にも sandbox 内の curl・git が TLS で接続できない（v2.1.288）。ホームの外の `.pem` は CA バンドルが主で、鍵はホームの下に置く前提
- ユーザー設定に `sandbox.filesystem.denyRead: ["~/"]` を置かない。`blockReadsOutsideWorkingDirectories` と併用すると、sandbox が作業ディレクトリを開け直さず、Bash から作業中のリポジトリを読めなくなる。ホームは block 自体が閉じる（v2.1.288）
- リポジトリ側の `permissions.additionalDirectories` は、`blockReadsOutsideWorkingDirectories` の下ではファイルツールにも sandbox にも効かない（v2.1.288、anthropics/claude-code#92582）。リポジトリ専用の場所もユーザー設定の `allowRead` に置き、後で実行されるプラグインの置き場所（nvim・zsh）には `allowWrite` を開けない
- `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB` は使わない。有効にすると `defaultMode: "auto"` が効かず、セッションが manual mode で始まる（Shift+Tab で auto には切り替えられる）（v2.1.280）
