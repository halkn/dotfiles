# shell・コマンド・herdr の設計

対象は zsh の設定（`.zshenv`・`.config/zsh/`）、独立したコマンド（`bin/`）、herdr のキーから実行する script（`.config/herdr/`）、それらのテスト（`test/`）。

## 原則

zsh の設定は、どのツールが欠けたマシンでもエラーなく起動する形に保つ。tool の初期化と plugin の読込は、それぞれの存在を確かめてから行う。herdr があるマシンでは、interactive zsh を herdr の中で使う（止めるのは `.zshrc.local`）。

独自の機能はコマンドのサブコマンドとして作り、shell が要らないものは shell の外に置く。

自作は git・gh・az・herdr の薄いラッパーに留める。判断（マージ済みか、変更を捨ててよいか）は各ツールに任せ、自作が持つのは置き場所の規約・引数の組み立て・ツール同士のつなぎだけにする。

tool の cache・state・data は XDG の各ディレクトリに置く。消えてはいけない作業物（worktree）は data の下に、特定の tool が所有するディレクトリの外に置く。

## どの層に置くか

| 層 | 持つもの | 持たないもの |
| --- | --- | --- |
| `.config/zsh/.zshenv` | 非対話のプロセス（`bin/`・herdr の script・agent の Bash）も読む環境変数と `path` | interactive でしか使わない設定 |
| `.config/zsh/.zshrc` | interactive zsh の基盤（history・options・completion・keybind・alias）と、tool の初期化。fzf 節の `hw` の補完 | 独自の関数 |
| `bin/repo` | clone の置き場所、list / get、create / setup（GitHub 側の設定） | herdr の知識 |
| `bin/hw` | herdr の操作の全て（workspace を開く・移動する・閉じる、worktree の作成・削除）と、picker・補完に渡す行データ。herdr を呼ぶのはこのコマンドだけ | picker・確認プロンプト |
| `.config/herdr/herdr-*.zsh` | herdr のショートカット 1 つにつき 1 本。focused な checkout に入る、`hw` から行を受け取る、fzf を開く、選んだ行のキーを `hw` に渡す、失敗したら止めて見せる、確認を 1 回出す | 分岐する判断、行の組み立て、`herdr` の呼び出し |
| `.config/herdr/ui.zsh` | herdr の script 同士で共有する表示の部品（fzf の見た目・プレビュー・`_ui_die`・`_ui_confirm`） | herdr への問い合わせ、他のファイルの source |

新しい操作をどこに置くかは、次の順に決める。

1. 既存の外部ツール（git の操作なら git-fz）で足りるなら、何も作らない
1. 選んで 1 つのコマンドを打つだけなら、関数を作らない。`.zshrc` の fzf 節にある `<command> **<TAB>` の補完に寄せる
1. stdout と終了コードで表せるなら、`bin/` のコマンドにする。clone なら `repo`、herdr の workspace と worktree なら `hw` のサブコマンドとして足す
1. 全画面の picker が要るなら、herdr の script にする。行は `hw` から受け取り、選んだ後の処理は `hw` を呼ぶ

どれにも当たらない対話的なヘルパーは作らない。外部ツールが名前で呼ぶフック関数（fzf の `_fzf_comprun`・`_fzf_complete_hw` など）は、独自の関数に当たらない。

`bin/` のコマンドは zsh の設定ファイルを source しない。shell と共有するのは `$REPO_ROOT`・`$WT_ROOT` とその下のレイアウトだけにする。どのサブコマンドも引数を渡せば対話せずに動き、終了コードは git・gh・az・herdr が返したものをそのまま返す。独自の終了コードで呼び出し側に確認を求めない。

## herdr の script の制約

- `ui.zsh` は、単独で source されても全ての関数を定義する形を保つ。冒頭の guard で `return` せず、依存の判定は各 script が `_ui_require` で行う
- picker は操作ごとに 1 本持つ。同じ行に対する別の操作だけは、別のキーで同じ picker に載せてよい
- picker の行はタブ区切りの `<表示>\t<キー>...` にし、表示列だけを見せる。script は表示用の文字列を解析しない
- 行は picker を開く前に取得し、失敗したら popup が閉じる前に止める（`_ui_die`）。キャンセルは成功（exit 0）として扱う
- script はリンク先のパス（`~/.config/herdr/...`）で `.config/herdr/config.toml` から呼ばれる。移動・改名するときは、`config.toml` の参照も同時に直す
- script（`herdr-*.zsh`）には実行ビットを付ける
- `.config/herdr/` は herdr の runtime state と同居するので、`.gitignore` で追跡するファイルだけを許可している。`config.toml`・直下の `*.zsh`・plugin の `config.toml` 以外のファイルを足すときは、`.gitignore` に `!` の行を足す。足さないと git にも `mise run lint` にも黙って含まれない

## script の書き方

- `set -e` は使わず、`set -uo pipefail` で書く。失敗するコマンドは、その場で扱い方を決める（`|| exit 1`・`|| _ui_die`・`|| rc=1`）
- 中身が zsh の script の拡張子は `.zsh` にする。`.sh` は bash / sh の script に使う

## worktree

| | `hw` / herdr | Claude Code |
| --- | --- | --- |
| 用途 | 人が戻ってくる作業場（herdr の workspace） | セッションや subagent の一時的な隔離 |
| 場所 | `$WT_ROOT/<owner>/<repo>/<branch の / を - にしたもの>` | `<repo>/.claude/worktrees/` |
| 作るのは | 人（alt+g の `hw branch`・alt+p の `hw pr`） | Claude Code |
| 消すのは | 人（alt+x・`hw rm`） | Claude Code |

両者を同じ場所に集約しない。Claude Code 側の設定は [claude-code.md](claude-code.md) にある。`hw rm` が消すのは `$WT_ROOT` の下のレイアウトに合う worktree だけで、メイン checkout と `.claude/worktrees/` は対象外にする。

worktree は git で作り、`herdr worktree open --cwd <メイン checkout> --path <path>` で開く。herdr 標準の `new_worktree` はキーを外す（`config.toml`）。

`$WT_ROOT` の場所を変えるときは、次の 3 箇所を揃える。

- `.config/zsh/.zshenv` の `$WT_ROOT`
- `.config/herdr/config.toml` の `[worktrees] directory`
- `bin/hw` の既定値（`$WT_ROOT` が未設定のときに使われる）

## テスト

- `bin/` のコマンドや `ui.zsh` の関数を足したり振る舞いを変えたりしたら、テストを足す。テストは直下の `test/` に置き、対象の置き場所に合わせて分ける（`bin/` → `test/bin/`、`.config/herdr/` → `test/herdr/`、`claude/hooks/` → `test/claude/`、`.config/git/hooks/` → `test/git/`）。`bin/` の中身は全て PATH に載るので、テストを `bin/` に入れない。Neovim のテストは [neovim.md](neovim.md) を参照
- `hw` のテストは、`herdr`・`gh`・`az` を PATH 上のスタブに置き換え、呼ばれた引数をログで照合する。git は一時リポジトリで実際に動かす
- picker を開く処理そのものは検査できない。行データと判断を `hw` に寄せて、そちらを検査する

次のものは lint でもテストでも確かめられない。実端末で新しいシェルを開いて確認する。

- fzf の widget と補完
- herdr の keybinding と `herdr-*.zsh`
- 追跡外の `.zshenv.local` / `.zshrc.local`

## 決定と理由

- `hw` は mise の trust を扱わない。mise を使うリポジトリは少なく、使うリポジトリではメイン checkout の trust がディレクトリ単位で worktree に引き継がれる。そのため fork の pull request が足した設定も trust され、これはメイン checkout で `gh pr checkout` したときと変わらない。止めるときは、その worktree で `mise trust --ignore` を実行する（mise 2026.10.19）
- herdr の Claude Code integration（`herdr integration install claude`）は入れない。書込先の `~/.claude/` の下は `claude/` へのリンクなので、追跡している設定を herdr が書き換え、追跡しない script がリポジトリに置かれる（herdr 0.9.5）。Codex の設定（`~/.codex`）はこのリポジトリが管理しないので、Codex の integration を入れるかはマシンごとに決める
- worktree を herdr の `worktree create` で作らない。origin にしか無いブランチを指定しても追跡せず、HEAD から新しいブランチを作る（herdr 0.9.5）
- worktree の workspace は `worktree open --cwd <メイン checkout>` で開き、`workspace create` を使わない。`worktree open` は既に開いている workspace に移動し（`already_open`）、git で作った worktree もメイン checkout の下にまとめて表示する。`workspace create` は同じパスに 2 つ目の workspace を作り、それはまとまらない。`--cwd` が無いと `worktree_not_found` で失敗する（herdr 0.9.5）
- `hw rm` は、worktree の上の workspace のペインでプロセスが動いていれば `-f` なしでは消さない。herdr の `worktree remove` は未コミットの変更は拒むが、動いているプロセスは確かめずに消す。動いているかは `pane process-info` の `foreground_process_group_id` が `shell_pid` と違うかで判定する（herdr 0.9.5）
- `hw rm` は、worktree の情報を持たず、ペインが全てその worktree の中にある workspace も閉じる（focused なものを除く）。`worktree remove` が閉じるのは worktree の情報を持つ workspace 1 つだけで、他は消えたディレクトリの上に残る（herdr 0.9.5）。別の checkout の workspace や、ペインが外にもある workspace は閉じず、中のペインを確かめて名前を出すだけにする
- `hw rm` は herdr の外（`HERDR_ENV` が無く、workspace の一覧を取れない）では git だけで消す。herdr の中で一覧を取れないときは、ペインを確かめられないので拒む
- ブランチを消すかは origin の既定ブランチで判定する。`git branch -d` と `git branch --delete-merged`（Git 2.56）は使わない。前者は upstream にマージされていれば通り、PR が開いたままの push 済みのブランチを消す。後者は upstream から辿れるかで判定するため squash merge を検出できない。`hw rm` は、既定ブランチに含まれるか、`git merge-tree --write-tree` で既定ブランチに取り込んでも tree が変わらないなら消す。変更の無いコミットだけのブランチも後者で消える
- herdr が custom command に渡す `HERDR_ACTIVE_WORKSPACE_ID` で focused な workspace を特定する。`HERDR_ACTIVE_PANE_CWD` はペインの `cd` で変わるので、workspace が checkout の上に無いときの代わりにだけ使う（herdr 0.9.5）
