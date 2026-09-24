# shell・コマンド・herdr の設計

対象は zsh の設定（`.zshenv`・`.config/zsh/`）、独立したコマンド（`bin/`）、herdr のキーから実行する script（`.config/herdr/`）、それらのテスト（`test/`）。

## 原則

zsh の設定は、どのツールが欠けたマシンでもエラーなく起動する形に保つ。tool の初期化と plugin の読込は、それぞれの存在を確かめてから行う。herdr があるマシンでは、interactive zsh を herdr の中で使う（止めるのは `.zshrc.local`）。

独自の機能はコマンドのサブコマンドとして作り、shell が要らないものは shell の外に置く。

tool の cache・state・data は XDG の各ディレクトリに置く。消えてはいけない作業物（worktree）は data の下に、特定の tool が所有するディレクトリの外に置く。

## どの層に置くか

| 層 | 持つもの | 持たないもの |
| --- | --- | --- |
| `.config/zsh/.zshenv` | 非対話のプロセス（`bin/`・herdr の script・agent の Bash）も読む環境変数と `path` | interactive でしか使わない設定 |
| `.config/zsh/.zshrc` | interactive zsh の基盤（history・options・completion・keybind・alias）と、tool の初期化 | 独自の関数 |
| `bin/`（`repo`・`wt`） | stdout と終了コードだけで表せる操作。picker に渡す行データと、`gh` などを使う外部サービスへの問い合わせと変更 | picker・`cd`・確認プロンプト・herdr の知識 |
| `.config/herdr/herdr-*.zsh` | herdr のキーから実行する、popup での選択・確認・移動と pane の操作 | 判断（`bin/` に寄せる） |
| `.config/herdr/ui.zsh` | herdr の script 同士で共有する部品 | 他のファイルの source |

新しい操作をどこに置くかは、次の順に決める。

1. 既存の外部ツール（git の操作なら git-fz）で足りるなら、何も作らない
1. 選んで 1 つのコマンドを打つだけなら、関数を作らない。`.zshrc` の fzf 節にある `<command> **<TAB>` の補完に寄せる
1. stdout と終了コードで表せるなら、`bin/` のコマンドにする。扱う対象が既存のコマンドと同じ（clone なら `repo`、worktree なら `wt`）なら、サブコマンドとして足す
1. 全画面の picker や herdr の操作が要るなら、herdr の script にする。選んだ後の処理は `bin/` のコマンドを呼ぶ

どれにも当たらない対話的なヘルパーは作らない。外部ツールが名前で呼ぶフック関数（fzf の `_fzf_comprun` など）は、独自の関数に当たらない。

`bin/` のコマンドは zsh の設定ファイルを source しない。shell と共有するのは `$REPO_ROOT`・`$WT_ROOT` とその下のレイアウトだけにして、いずれこのリポジトリの外へ切り出せる状態を保つ。確認が要るかどうかは終了コードで伝え、ユーザーが決めた結果はフラグで受け取る。

## herdr の script の制約

- `ui.zsh` は、単独で source されても全ての関数を定義する形を保つ。冒頭の guard で `return` せず、依存の判定は各 script が `_ui_require` で行う
- picker は操作ごとに 1 本持つ。同じ行に対する別の操作だけは、別のキーで同じ picker に載せてよい
- script はリンク先のパス（`~/.config/herdr/...`）で `.config/herdr/config.toml` から呼ばれる。移動・改名するときは、`config.toml` の参照も同時に直す
- エラーを見せる経路では、popup が閉じる前に止める（`_ui_die`）
- script（`herdr-*.zsh`）には実行ビットを付ける

## script の書き方

- `set -e` は使わず、`set -uo pipefail` で書く。失敗するコマンドは、その場で扱い方を決める（`|| exit 1`・`|| _ui_die`・`|| rc=1`）
- 中身が zsh の script の拡張子は `.zsh` にする。`.sh` は bash / sh の script に使う

## worktree

| | `wt` / herdr | Claude Code |
| --- | --- | --- |
| 用途 | 人が戻ってくる作業場 | セッションや subagent の一時的な隔離 |
| 場所 | `$WT_ROOT` | `<repo>/.claude/worktrees/` |
| 消すのは | 人（`wt rm` / `wt prune`） | Claude Code |

両者を同じ場所に集約しない。Claude Code 側の設定は [claude-code.md](claude-code.md) にある。

`$WT_ROOT` の場所を変えるときは、次の 3 箇所を揃える。

- `.config/zsh/.zshenv` の `$WT_ROOT`
- `.config/herdr/config.toml` の `[worktrees] directory`
- `bin/wt` の既定値（`$WT_ROOT` が未設定のときに使われる）

## テスト

- `bin/` のコマンドや `ui.zsh` の関数を足したり振る舞いを変えたりしたら、テストを足す。テストは直下の `test/` に置き、対象の置き場所に合わせて分ける（`bin/` → `test/bin/`、`.config/herdr/` → `test/herdr/`）。`bin/` の中身は全て PATH に載るので、テストを `bin/` に入れない。Neovim のテストは [neovim.md](neovim.md) を参照
- picker を開く処理そのものは検査できない。行データと判断を `bin/` に寄せて、そちらを検査する

次のものは lint でもテストでも確かめられない。実端末で新しいシェルを開いて確認する。

- fzf の widget と補完
- herdr の keybinding と `herdr-*.zsh`
- 追跡外の `.zshenv.local` / `.zshrc.local`
