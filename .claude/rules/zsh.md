---
paths:
  - ".config/zsh/**"
  - ".config/herdr/**"
  - "**/*.zsh"
  - ".zshenv"
---

# zsh Design Principles

方針: 「`.zshenv` / `.zshrc` は portable な shell core。独自機能は操作をサブコマンドで表し、内部は扱う情報で分ける」

**置き場所:**

- `.zshrc`: interactive zsh を成立させる基盤（history・options・completion・keybind・alias）と、軽量な tool init。fzf の widget や `eza`・`nvim` の上書きのように、無くても標準の動作が残るものはここで `command -v` 分岐する
- `.config/zsh/workflows/*.zsh`: ユーザーが打つコマンド（`wk`・`gst`）。操作はサブコマンドで表す。新しい操作は新ファイルではなくサブコマンドとして足す
- `.config/zsh/lib/*.zsh`: 扱う情報ごとの層。`checkout`（ローカルの path 規約）・`forge`（リモートの forge）・`session`（herdr）・`ui`（fzf chrome・依存チェック・preview）。分割の軸に外部ツール名を使わない。`session` を herdr を呼ぶ唯一の層にする形で境界を作る
- lib は workflows も他の lib も source しない。他層の情報が要るときは呼び出し側が引数で渡す（`_forge_repo_rows <root> ...`）。workflow は自身の path から必要な lib を source する
- workflow に function を置くのは「選択の後に判断が続く」とき（cd 先・削除の可否・ピッカー内で完結する stage / restore）。選択 + 単一コマンドで終わるものは function を作らず、`.zshrc` の `_fzf_comprun` / `_fzf_complete_<cmd>` に寄せて `<コマンド> **<TAB>` から引く
- fzf の共通オプション（見た目・キー）は `.zshrc` の `FZF_DEFAULT_OPTS`。候補生成と preview はコマンド側の関心なので、行データは lib の function を呼んで得る
- checkout の状態は git に聞く。zsh 側に状態のキャッシュや在庫を持たない。一覧は path のレイアウト（`$WT_ROOT/<owner>/<repo>/<branch>`・`$REPO_ROOT/<host>/<...>/<repo>`）から作り、git を呼ぶのは preview と実行の瞬間だけにする（行数分の process を増やさない）

**構造上の制約:**

- `.zshrc` は `workflows/*.zsh` だけを glob で source する。lib の登録は要らず、読み込み順にも依存しない
- **ファイル冒頭で `return 0` しない。** function は常に定義し、依存判定は各エントリポイントの内部で `_ui_require <tool> <コマンド名>` を呼んで行う。file-level guard だと function 自体が消えて `command not found` になり、herdr から単独 source されるファイルでは沈黙して壊れる
- ピッカーは操作ごとに 1 本持つ（`_wk_go_pick`・`_wk_open_pick`・`_wk_rm`）。行の意味も遷移先も違うものを 1 本に畳まない。行は `<display>\t<target>\t<path>` で揃え、preview は path 列だけを見る
- 全画面で開くピッカーの見た目は `_UI_FZF_CHROME` が持つ。`.config/herdr/*.sh` はピッカーを開くなら workflow を 1 本 source して関数を呼ぶだけにし、herdr の CLI だけで完結するものは zsh 側に function を作らずその script に閉じる。`FZF_DEFAULT_OPTS` はカーソル下に出る補完用の寸法なので、そこへ寄せない。herdr の script は絶対パスで source するので、移動・改名は herdr 側の参照と同時に直す
- herdr から source される関数は `set -euo pipefail` 下（herdr picker・fzf の preview）で走る。herdr や jq を呼ぶ箇所は結果を変数に受けてから出力し、途中の失敗で一覧や preview 全体が消えないようにする
- worktree の置き場所は `.zshenv` の `$WT_ROOT` と herdr の `[worktrees] directory` を一致させる。片方だけ変えない
- `.claude/worktrees/` の lifecycle は Claude Code が持つ。`$WT_ROOT` の外なので `wk` の一覧には出ず、`wk rm` の候補からは path で除外する
- 破壊的操作を git に委ねるときは、git が拒否しないものを先に列挙する。`git worktree remove` は「今立っている worktree」も消すので、そこは zsh 側で止める
- OS 固有処理は必要箇所に局所化する。macOS / WSL の分岐を持ち込まない

**言語上の注意:**

- zsh の `path` は PATH の配列。worktree のパスを入れる変数に `local path` を使うと関数内で PATH が消える（`wt_path` を使う）
- `.zshenv.local` / `.zshrc.local` は lint 対象外。共有したい設定をここに書かない
- zsh 固有構文の検索・変換で `ast-grep` を既定にしない。対応 parser を確認できない場合は `rg` と既存の `shuck` に寄せる
- fzf の widget・completion と herdr の picker・自動起動は lint で確認できない。実端末で新規シェルを開いて確認する
