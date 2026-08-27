---
paths:
  - ".config/zsh/**"
  - ".config/herdr/**"
  - "**/*.zsh"
  - ".zshenv"
---

# zsh Design Principles

方針: 「`.zshenv` / `.zshrc` は portable な shell core。独自機能はツール名ではなく workflow 単位で分ける」

**置き場所:**

- `.zshrc`: interactive zsh を成立させる基盤（history・options・completion・keybind・alias）と、軽量な tool init。fzf の widget や `eza`・`nvim` の上書きのように、無くても標準の動作が残るものはここで `command -v` 分岐する
- `.config/zsh/workflows/*.zsh`: ユーザーの操作単位で分けた独自機能（`worktree` / `repo` / `git`）。新しい function はどの workflow の操作かで置き場所を決める。既存に収まらない責務のときだけファイルを足す
- 分割の軸に外部ツール名を使わない。picker backend を切り替えるためだけの抽象も作らない
- workflow に function を置くのは「選択の後に判断が続く」とき（cd 先・削除の可否・ピッカー内で完結する stage / restore）。選択 + 単一コマンドで終わるものは function を作らず、`.zshrc` の `_fzf_comprun` / `_fzf_complete_<cmd>` に寄せて `<コマンド> **<TAB>` から引く
- fzf の共通オプション（見た目・キー）は `.zshrc` の `FZF_DEFAULT_OPTS`。候補生成と preview はコマンド側の関心なので、行データは workflow の function を呼んで得る
- checkout の状態は git に聞く。zsh 側に状態のキャッシュや在庫を持たない。一覧は path のレイアウト（`$WT_ROOT/<owner>/<repo>/<branch>`・`$REPO_ROOT/<host>/<...>/<repo>`）から作り、git を呼ぶのは preview と実行の瞬間だけにする（行数分の process を増やさない）

**workflows/ の制約:**

- `.zshrc` が glob で source するので登録は不要。読み込み順に依存させない（相互 source をしない）
- **ファイル冒頭で `return 0` しない。** function は常に定義し、依存判定は各エントリポイントの内部で行って `<コマンド名>: <tool> is not installed` を stderr に出し非 0 で返す。file-level guard だと function 自体が消えて `command not found` になり、herdr から単独 source されるファイルでは沈黙して壊れる
- ピッカーはコマンドごとに 1 本持つ（`wt` は `_wt_pick`、`repo` は `_repo_pick`）。行の意味も遷移先も違うものを 1 本に畳まない
- 全画面で開くピッカーの見た目は呼び出し側ではなく workflow が持つ（`worktree.zsh` の `_WT_FZF_CHROME`）。`.config/herdr/herdr-picker.sh` は source して関数を呼ぶだけにする。`FZF_DEFAULT_OPTS` はカーソル下に出る補完用の寸法なので、そこへ寄せない。picker script は `worktree.zsh` を絶対パスで source するので、移動・改名は herdr 側の参照と同時に直す
- `worktree.zsh` の関数は `set -euo pipefail` 下（herdr picker・fzf の preview）で走る。herdr や jq を呼ぶ箇所は結果を変数に受けてから出力し、途中の失敗で一覧や preview 全体が消えないようにする
- `.claude/worktrees/` の lifecycle は Claude Code が持つ。`$WT_ROOT` の外なので `wt` の一覧には出ず、`wt rm` の候補からは path で除外する
- 破壊的操作を git に委ねるときは、git が拒否しないものを先に列挙する。`git worktree remove` は「今立っている worktree」も消すので、そこは zsh 側で止める
- OS 固有処理は必要箇所に局所化する。workflow に macOS / WSL の分岐を持ち込まない

**言語上の注意:**

- zsh の `path` は PATH の配列。worktree のパスを入れる変数に `local path` を使うと関数内で PATH が消える（`wt_path` を使う）
- `.zshenv.local` / `.zshrc.local` は lint 対象外。共有したい設定をここに書かない
- zsh 固有構文の検索・変換で `ast-grep` を既定にしない。対応 parser を確認できない場合は `rg` と既存の `shuck` / `zsh -n` に寄せる
- fzf の widget・completion と herdr の picker・自動起動は lint で確認できない。実端末で新規シェルを開いて確認する
