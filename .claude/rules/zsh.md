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
- `.config/zsh/workflows/*.zsh`: ユーザーの操作単位で分けた独自機能（`repo` / `worktree` / `git`）。新しい function はどの workflow の操作かで置き場所を決める。既存に収まらない責務のときだけファイルを足す
- 分割の軸に外部ツール名を使わない。picker backend を切り替えるためだけの抽象も作らない
- workflow に function を置くのは「選択の後に判断が続く」とき（cd 先・削除の可否・ピッカー内で完結する stage / restore）。選択 + 単一コマンドで終わるものは function を作らず、`.zshrc` の `_fzf_comprun` / `_fzf_complete_<cmd>` に寄せて `<コマンド> **<TAB>` から引く
- fzf の共通オプション（見た目・キー）は `.zshrc` の `FZF_DEFAULT_OPTS`。候補生成と preview はコマンド側の関心なので、行データを workflow が計算するもの（`wt` のフラグ、`repo` の配置規約、staging の一覧）は workflow の function を呼んで得る

**workflows/ の制約:**

- `.zshrc` が glob で source するので登録は不要。読み込み順に依存させない（相互 source をしない）
- **ファイル冒頭で `return 0` しない。** function は常に定義し、依存判定は各エントリポイントの内部で行って `<コマンド名>: <tool> is not installed` を stderr に出し非 0 で返す。file-level guard だと function 自体が消えて `command not found` になり、herdr から単独 source されるファイルでは沈黙して壊れる
- `.config/herdr/herdr-picker.sh` は `workflows/repo.zsh` と `workflows/worktree.zsh` を絶対パスで source する。移動先の一覧（`_wt_nav_rows`）・preview・移動・削除のロジックはここに集約し、picker 側で再実装しない。picker が持つのは agent の一覧とモード切替だけ。パスが外部との契約なので、移動・改名は herdr 側の参照と同時に直す
- workspace / worktree / repo は 1 本の一覧に畳む（`_wt_nav_merge` がチェックアウトパスで重複排除する）。新しい移動先を足すときは `<kind>:<target>` のタグ付き行を出す producer を `worktree.zsh` に足し、`_wt_nav_open` に分岐を 1 つ加える
- forge（GitHub / Azure DevOps）の差異は `worktree.zsh` 末尾の `_forge_*` 節に集約する。`wt` 本体と `repo` は `gh` / `az` の癖を持たない。`repo` の URL 正規化は例外で `repo.zsh` に残す（origin ではなく引数から host を決めるため入口が違う）
- `.claude/worktrees/` 配下の lifecycle は Claude Code が持つ。`wt` の一覧には出しつつ、`wt clean` の削除対象からは外す
- OS 固有処理は必要箇所に局所化する。workflow に macOS / WSL の分岐を持ち込まない

**言語上の注意:**

- zsh の `path` は PATH の配列。worktree のパスを入れる変数に `local path` を使うと関数内で PATH が消える（`wt_path` を使う）
- `.zshenv.local` / `.zshrc.local` は lint 対象外。共有したい設定をここに書かない
- zsh 固有構文の検索・変換で `ast-grep` を既定にしない。対応 parser を確認できない場合は `rg` と既存の `shuck` / `zsh -n` に寄せる
- fzf の widget・completion と herdr の picker・自動起動は lint で確認できない。実端末で新規シェルを開いて確認する
