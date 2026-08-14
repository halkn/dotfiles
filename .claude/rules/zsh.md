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

- `.zshrc`: interactive zsh を成立させる基盤（history・options・completion・keybind・alias）と、軽量な tool init。`fzf` の widget や `eza`・`nvim` の上書きのように、無くても標準の動作が残るものはここで `command -v` 分岐する
- `.config/zsh/workflows/*.zsh`: ユーザーの操作単位で分けた独自機能（`filesystem` / `git` / `repo` / `worktree`）。新しい function はどの workflow の操作かで置き場所を決める。既存 4 つに収まらない責務のときだけファイルを足す
- 分割の軸に外部ツール名を使わない。`fzf` / Television のような picker backend を切り替えるためだけの抽象も作らない

**workflows/ の制約:**

- `.zshrc` が glob で source するので登録は不要。読み込み順に依存させない（相互 source をしない）
- **ファイル冒頭で `return 0` しない。** function は常に定義し、依存判定は各エントリポイントの内部で行って `<コマンド名>: <tool> is not installed` を stderr に出し非 0 で返す。file-level guard だと function 自体が消えて `command not found` になり、herdr から単独 source されるファイルでは沈黙して壊れる
- `workflows/worktree.zsh`（`wt`）は `.config/herdr/herdr-picker.sh`、`workflows/repo.zsh`（`repo`）は `.config/herdr/herdr-repo-workspace.sh` から絶対パスで source される。worktree の一覧・削除、リポジトリの一覧・preview のロジックはここに集約し、呼び出し側で再実装しない。パスが外部との契約なので、移動・改名は herdr 側の参照と同時に直す
- forge（GitHub / Azure DevOps）の差異は `worktree.zsh` 末尾の `_forge_*` 節に集約する。`wt` 本体と `repo` は `gh` / `az` の癖を持たない。`repo` の URL 正規化は例外で `repo.zsh` に残す（origin ではなく引数から host を決めるため入口が違う）
- `wt` が lifecycle を持つのは人間が作った persistent worktree だけ。`.claude/worktrees/` 配下は Claude Code が作る ephemeral な checkout で、削除は向こうの sweep が持つ。一覧には出しつつ削除対象からは外す
- OS 固有処理は必要箇所に局所化する。workflow に macOS / WSL の分岐を持ち込まない

**言語上の注意:**

- zsh の `path` は PATH の配列。worktree のパスを入れる変数に `local path` を使うと関数内で PATH が消える（`wt_path` を使う）
- 端末固有の設定は追跡外の `.zshenv.local`（環境変数）・`.zshrc.local`（インタラクティブ）に置く。どちらも lint 対象外なので、共有したい設定をここに書かない
- zsh 固有構文の検索・変換で `ast-grep` を既定にしない。対応 parser を確認できない場合は `rg` と既存の `shuck` / `zsh -n` に寄せる

**変更時の手順:**

1. `mise run fmt` で整形（`shuck`）
1. `mise run lint` で確認（`zsh -n`・`shuck check`・`shuck format --check`・`test/*_test.zsh`）
1. 対話動作（fzf の widget、herdr の picker と自動起動）は lint で確認できない。実端末で新規シェルを開いて確認し、PR にその内容を 1 行添える
