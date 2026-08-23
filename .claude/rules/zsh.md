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
- `.config/zsh/workflows/*.zsh`: ユーザーの操作単位で分けた独自機能（`nav` / `repo` / `worktree` / `git`）。新しい function はどの workflow の操作かで置き場所を決める。既存に収まらない責務のときだけファイルを足す
- 分割の軸に外部ツール名を使わない。picker backend を切り替えるためだけの抽象も作らない
- workflow に function を置くのは「選択の後に判断が続く」とき（cd 先・削除の可否・ピッカー内で完結する stage / restore）。選択 + 単一コマンドで終わるものは function を作らず、`.zshrc` の `_fzf_comprun` / `_fzf_complete_<cmd>` に寄せて `<コマンド> **<TAB>` から引く
- fzf の共通オプション（見た目・キー）は `.zshrc` の `FZF_DEFAULT_OPTS`。候補生成と preview はコマンド側の関心なので、行データは workflow の function を呼んで得る
- checkout（repository と worktree）の判断は `trepo` が持つ。存在・所属・状態フラグ・配置先・削除可否を zsh で再計算しない。zsh に残るのは選択・行の整形・`cd`・herdr workspace の追随。`trepo` の出力だけでは描けない情報が出たら、zsh で git を叩く前に trepo 側へ足せないかを先に問う

**workflows/ の制約:**

- `.zshrc` が glob で source するので登録は不要。読み込み順に依存させない（相互 source をしない）
- **ファイル冒頭で `return 0` しない。** function は常に定義し、依存判定は各エントリポイントの内部で行って `<コマンド名>: <tool> is not installed` を stderr に出し非 0 で返す。file-level guard だと function 自体が消えて `command not found` になり、herdr から単独 source されるファイルでは沈黙して壊れる
- 移動のピッカーは `workflows/nav.zsh` の `_nav_go` 1 本。`wt`(引数なし)・`repo`・`.config/herdr/herdr-picker.sh` は見た目（fzf の chrome）と初期クエリだけを渡し、行・preview・キーは再実装しない。picker script は絶対パスで `repo.zsh` / `worktree.zsh` / `nav.zsh` を source するので、移動・改名は herdr 側の参照と同時に直す
- 依存は `nav.zsh` → `repo.zsh` / `worktree.zsh` の一方向。逆向きに呼ばない（`wt` / `repo` コマンド本体が `nav.zsh` にあるのはこのため）
- workspace / worktree / repo / agent は 1 本の一覧に畳む（`_nav_merge` がチェックアウトパスで重複排除する）。新しい移動先を足すときは `<kind>:<target>` のタグ付き行を出す producer を `nav.zsh` に足し、`_nav_open` に分岐を 1 つ加える
- `nav.zsh` の関数は `set -euo pipefail` 下（herdr picker・fzf の preview / transform）で走る。herdr や jq を呼ぶ箇所は結果を変数に受けてから出力し、途中の失敗で一覧や preview 全体が消えないようにする
- forge（GitHub / Azure DevOps）の差異は `worktree.zsh` 末尾の `_forge_*` 節に集約する。`wt` 本体と `repo` は `gh` / `az` の癖を持たない。pull request は `trepo` が扱わない唯一の領域なので、ここだけ zsh が git を直接呼ぶ
- `.claude/worktrees/` 配下の lifecycle は Claude Code が持つ。`wt` の一覧には出しつつ、`wt clean` の削除対象からは外す。除外は zsh の分岐ではなく `.config/git/config` の `trepo.protected` で表す
- OS 固有処理は必要箇所に局所化する。workflow に macOS / WSL の分岐を持ち込まない

**言語上の注意:**

- zsh の `path` は PATH の配列。worktree のパスを入れる変数に `local path` を使うと関数内で PATH が消える（`wt_path` を使う）
- `.zshenv.local` / `.zshrc.local` は lint 対象外。共有したい設定をここに書かない
- zsh 固有構文の検索・変換で `ast-grep` を既定にしない。対応 parser を確認できない場合は `rg` と既存の `shuck` / `zsh -n` に寄せる
- fzf の widget・completion と herdr の picker・自動起動は lint で確認できない。実端末で新規シェルを開いて確認する
