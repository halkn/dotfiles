---
paths:
  - ".config/zsh/**"
  - ".config/herdr/**"
  - "**/*.zsh"
  - ".zshenv"
---

# zsh Design Principles

方針: 「`.zshrc` は素の zsh でも成立させ、外部 CLI への依存は外に出す」

**置き場所:**

- `.zshrc`: 外部 CLI に依存しない設定（history・options・completion・keybind・alias）と、`eza`・`nvim` のように無くても標準コマンドで代替できるものの上書き。`command -v` で分岐し、CLI が無い環境では標準コマンドのまま動くこと
- `.config/zsh/integrations/*.zsh`: `fzf`・`herdr` のように UX を大きく変える、または function を提供する外部 CLI 前提の設定。alias 1 行で済むものはここに置かず `.zshrc` に書く
- `.config/zsh/lib/*.zsh`: 他のスクリプトからも source される関数群

**integrations/ の制約:**

- `.zshrc` が glob で source するので登録は不要。代わりに各ファイルが冒頭で自分の依存を判定して `return 0` する（`integrations/fzf.zsh` を踏襲）
- 読み込み順は `lib/` → `integrations/` のファイル名順。`exec herdr` を持つ `herdr.zsh` が最後に来ることに依存しているため、それより後に読ませたいファイルを足すときは順序の作り方から見直す

**lib/ の制約:**

- `lib/worktree.zsh`（`wt`）は `.config/herdr/herdr-picker.sh`、`lib/repo.zsh`（`repo`）は `.config/herdr/herdr-repo-workspace.sh` から絶対パスで source される。worktree の一覧・削除、リポジトリの一覧・preview のロジックはここに集約し、呼び出し側で再実装しない
- パスが外部との契約になっているので、移動・改名は herdr 側の参照と同時に直す
- forge（GitHub / Azure DevOps）の差異は `lib/forge.zsh` に集約する。`wt` は worktree、`repo` はリポジトリ配置の層で、どちらも `gh` / `az` の癖を持たない。ただし `repo` の URL 正規化は例外で `repo.zsh` に残す（origin ではなく引数から host を決めるため入口が違い、`repo.zsh` は herdr から単独 source される）
- `wt` が lifecycle を持つのは人間が作った persistent worktree だけ。`.claude/worktrees/` 配下は Claude Code が作る ephemeral な checkout で、削除は向こうの sweep が持つ。一覧には出しつつ削除対象からは外す

**言語上の注意:**

- zsh の `path` は PATH の配列。worktree のパスを入れる変数に `local path` を使うと関数内で PATH が消える（`wt_path` を使う）
- 端末固有の設定は追跡外の `.zshenv.local`（環境変数）・`.zshrc.local`（インタラクティブ）に置く。どちらも lint 対象外なので、共有したい設定をここに書かない
- zsh 固有構文の検索・変換で `ast-grep` を既定にしない。対応 parser を確認できない場合は `rg` と既存の `shuck` / `zsh -n` に寄せる

**変更時の手順:**

1. `mise run fmt` で整形（`shuck`）
1. `mise run lint` で確認（`zsh -n`・`shuck check`・`shuck format --check`）
1. 対話動作（fzf の widget、herdr の自動起動）は lint で確認できない。実端末で新規シェルを開いて確認し、PR にその内容を 1 行添える
