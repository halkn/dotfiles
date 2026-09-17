---
paths:
  - ".config/zsh/**"
  - ".config/herdr/**"
  - "**/*.zsh"
  - ".zshenv"
---

# zsh Design Principles

方針: 「`.zshenv` / `.zshrc` は portable な shell core。独自機能は操作をサブコマンドで表し、内部は扱う情報で分ける」。検証手順は `/zsh-workflows` skill。

**層と責務:**

- `.zshrc`: interactive zsh を成立させる基盤（history・options・completion・keybind・alias）と、軽量な tool init。無くても標準の動作が残るものは `command -v` で分岐し、ツールの無い機械でも shell が成立するようにする
- `workflows/*.zsh`: ユーザーが打つコマンド。操作はサブコマンドで表す。新しい操作は、既存コマンドが扱う対象と同じならサブコマンドとして足す。対象が別のときだけ新ファイルにする
- `lib/*.zsh`: 扱う情報ごとの層。分割の軸に外部ツール名を使わない。特定の外部ツールを呼ぶ層は 1 つに絞り、そこを境界にする
- 依存は workflow → lib の一方向。lib は workflow も他の lib も source しない。他層の情報が要るときは呼び出し側が引数で渡す
- workflow に function を置くのは「選択の後に判断が続く」とき。選択 + 単一コマンドで終わるものは function を作らず、`.zshrc` の fzf 補完（`<コマンド> **<TAB>`）に寄せる
- fzf の共通オプション（見た目・キー）は `.zshrc` が持つ。候補生成と preview はコマンド側の関心なので、行データは lib の function を呼んで得る
- checkout の状態は git に聞く。zsh 側に状態のキャッシュや在庫を持たない。一覧は path のレイアウトから作り、git を呼ぶのは preview と実行の瞬間だけにする（行数分の process を増やさない）

**構造上の制約:**

- `.zshrc` は `workflows/*.zsh` だけを glob で source する。lib の登録は要らず、読み込み順にも依存しない
- **ファイル冒頭で `return 0` しない。** function は常に定義し、依存判定は各エントリポイントの内部で行う。file-level guard だと function 自体が消えて `command not found` になり、herdr から単独 source されるファイルでは沈黙して壊れる
- ピッカーは操作ごとに 1 本持つ。行の意味も遷移先も違うものを 1 本に畳まない。行の形式は揃え、preview は path を持つ列だけを見る
- 全画面のピッカーと、カーソル下に出る補完用のピッカーは寸法が別物。片方の設定へ寄せない
- herdr から source される関数は `set -euo pipefail` 下で走る。外部コマンドを呼ぶ箇所は結果を変数に受けてから出力し、途中の失敗で一覧や preview 全体が消えないようにする。herdr の script は絶対パスで source するので、移動・改名は herdr 側の参照と同時に直す
- worktree の置き場所は `.zshenv` の `$WT_ROOT` と herdr の設定を一致させる。片方だけ変えない
- `.claude/worktrees/` の lifecycle は Claude Code が持つ。`$WT_ROOT` の外なので一覧に出さず、削除の候補からも path で除外する
- 破壊的操作を git に委ねるときは、git が拒否しないものを先に列挙する。今立っている worktree の削除のように git が通してしまうものは zsh 側で止める
- OS 固有処理は必要箇所に局所化する。macOS / WSL の分岐を持ち込まない
- zsh の `path` は PATH の配列。関数内で `local path` を宣言すると PATH が消える
