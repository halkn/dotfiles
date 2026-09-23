---
description: このリポジトリの zsh 設定を変更するときに使う。設計方針・検証手順・実測記録を持つ。対象は .config/zsh 配下の .zshenv・.zshrc・workflows/・test/ と .config/herdr/（*.sh・ui.zsh）・bin/。関数・コマンドをどの層に置くか決める、bin/ のコマンドにサブコマンドを足す・直す、picker の挙動を変える、test/ に検査を足す、herdr から呼ばれる script を直す、といった作業。
---

# zsh workflow

方針: 「`.zshenv` / `.zshrc` は portable な shell core。独自機能は操作をサブコマンドで表し、内部は扱う情報で分ける。shell を必要としないものは shell の外に置く」。

## 設計方針

**置き場所:**

- `.zshrc`: interactive zsh を成立させる基盤（history・options・completion・keybind・alias）と、軽量な tool init。fzf の widget や `eza`・`nvim` の上書きのように、無くても標準の動作が残るものはここで `command -v` 分岐する
- **`bin/` と `workflows/` の線引きが最初の判断**: stdout と終了ステータスだけで表せる操作は `bin/` の実行ファイル（`repo`・`wt`）。shell でしかできないこと——`cd`・ピッカーを開いたまま続く操作——を含むものだけ `workflows/` の関数（現在は無い）。`bin/` のコマンドは他の zsh ファイルを source せず、shell と共有するのは環境変数とレイアウトの規約だけにする。これはこのリポジトリの外へ出せる状態を保つための線で、守れていれば切り出しはファイル移動で済む
- `bin/` のコマンドは作成・削除したものの path を stdout に出し、そこへ移動する・workspace を開閉するのは呼び出し側（herdr script）に任せる。確認プロンプトは持たない。呼び出し側が確認を出すべきかは終了コードで伝え（`wt rm` の 2 = `-f` なら通る）、判断は `-f` などのフラグで受け取る
- picker の行データ（一覧・整形）も `bin/` が `<display>\t<target>` で出す（`wt prs`・`repo list`）。外部 CLI（`gh` など）を呼ぶのは `bin/` 側に寄せ、script が直接知るのは fzf・herdr CLI と preview だけにする。herdr の workspace の行だけは `bin/` が知り得ないので ui.zsh の `_ui_workspaces` が出す
- 選択・確認・移動は `.config/herdr/*.sh` が持つ。`bin/` のコマンドと herdr CLI だけで組み、判断を持たない。共有するのは `.config/herdr/ui.zsh`（依存チェック・`_ui_pause` / `_ui_die` / `_ui_confirm`・fzf chrome・preview・workspace の行）だけで、ui.zsh は何も source しない
- `.config/zsh/workflows/*.zsh`: ユーザーが打つ shell 関数。操作はサブコマンドで表す。対象が既存コマンドと同じならサブコマンドとして足し、別のときだけ新ファイルにする
- branch・commit・staging の選択は `git-fz`（`git fz switch` / `log` / `stage`）が持つ。zsh 側に再実装せず、足りない操作は git-fz 側の Issue にする
- 選択 + 単一コマンドで終わるものは function を作らず、`.zshrc` の `_fzf_comprun` / `_fzf_complete_<cmd>` に寄せて `<コマンド> **<TAB>` から引く
- fzf の共通オプション（見た目・キー）は `.zshrc` の `FZF_DEFAULT_OPTS`。候補生成と preview はコマンド側の関心
- checkout の状態は git に聞く。状態のキャッシュや在庫を持たない。一覧は path のレイアウト（`$WT_ROOT/<owner>/<repo>/<branch>`）から作り、git を呼ぶのは preview と実行の瞬間だけにする（行数分の process を増やさない）

**構造上の制約:**

- `.zshrc` は `workflows/*.zsh` だけを glob で source する。登録は要らず、読み込み順にも依存しない
- **ファイル冒頭で `return 0` しない。** function は常に定義し、依存判定は各エントリポイントの内部で `_ui_require <tool> <コマンド名>` を呼んで行う。file-level guard だと function 自体が消えて `command not found` になり、herdr から単独 source されるファイルでは沈黙して壊れる
- ピッカーは操作ごとに 1 本持つ。行の意味も遷移先も違うものを 1 本に畳まない。同じ行への別の操作は別キー（`--expect`）で同じピッカーに載せてよい（`herdr-spaces.sh` の ctrl-x）。行は `<display>\t<target>\t<path>` で揃え、preview は path 列だけを見る
- 全画面で開くピッカーの見た目は `_UI_FZF_CHROME` が持つ（`--border-label` は呼び出し側がコマンド名で付ける）。`FZF_DEFAULT_OPTS` はカーソル下に出る補完用の寸法なので、そこへ寄せない。herdr の script は絶対パスで source・起動されるので、移動・改名は herdr 側の参照と同時に直す
- herdr script は `set -euo pipefail` 下で走り、popup は終了と同時に閉じる。herdr や jq を呼ぶ箇所は結果を変数に受けてから出力し、失敗や `wt` の stderr を見せる経路では `_ui_die` / `_ui_pause` で閉じる前に止める
- worktree の置き場所は `.zshenv` の `$WT_ROOT` と herdr の `[worktrees] directory` を一致させる。片方だけ変えない
- `.claude/worktrees/` の lifecycle は Claude Code が持つ。`wt rm` は `$WT_ROOT` 配下の layout に一致する path しか受け付けないことで除外する
- 破壊的操作を git に委ねるときは、git が拒否しないものを先に列挙する。`git worktree remove` は「今立っている worktree」も消すので、そこは `wt` 側で止める
- OS 固有処理は必要箇所に局所化する。macOS / WSL の分岐を持ち込まない
- zsh の `path` は PATH の配列。関数内で `local path` を宣言すると PATH が消える（`wt_path` を使う）

## 手順

1. `mise run fmt` で整形する（`shuck format .`）
1. `mise run lint` で確認する（`shuck` の検査と `test/` の実行を含む）
1. zsh だけを回すときは `mise run test:zsh`
1. ツールが無い場合は先に `mise install`

`shuck` はリポジトリ全体（`.`）が対象。シェルスクリプトを足しても `mise.toml` への登録は要らない。

## test/ に検査を足す

`.config/zsh/test/` は 1 ファイル 1 対象で、何を見るかはファイル冒頭のコメントにある。

- source される関数（`ui.zsh`）は `zsh -df` の子プロセスで source し、依存コマンドを関数で差し替えて出力を照合する（`ui_test.zsh`）。`$WT_ROOT` / `$REPO_ROOT` はテスト内で差し替える
- picker を開く処理そのものは検査できない。行データや判断は `bin/` 側に寄せて、そちらを検査対象にする
- `bin/` の実行ファイルは source できない。サブプロセスとして起動し stdout を照合する（`repo_test.zsh`・`wt_test.zsh`）。依存不在の経路は zsh だけを置いた stub PATH で叩く——shebang も PATH で解決されるので、空の PATH では起動自体が失敗する
- git を使う検査は `$TMPDIR` に一時 repo と bare の origin を作り、`HOME`・`XDG_CONFIG_HOME`・`GIT_CONFIG_GLOBAL` を差し替える（`XDG_CONFIG_HOME` を残すと追跡下の `.config/git/config` に書き込む）。`gh` は PATH 先頭の stub で答える（`wt_test.zsh`）

## 検査の届かない範囲

lint も test も次を見ないので、実端末で新規シェルを開いて確認する。

- fzf の widget・completion（`Ctrl-R` / `Ctrl-T` / `Alt-C` / `<command> **<TAB>`）
- herdr の keybinding と `.config/herdr/*.sh`（`herdr config check` は設定の構文だけを見る）
- `.zshenv.local` / `.zshrc.local` は追跡外で lint 対象外

## 実測記録

- `herdr workspace list`（0.9.1）は workspace id・番号・ラベル・`focused` を返し、git checkout 上の workspace にだけ `worktree.checkout_path` が付く。**branch と、checkout 外の workspace の cwd は返さない**。一覧の行名は path から作り、現在の workspace は `focused` で判定する。`herdr` は sandbox 内から実行すると `PermissionDenied`（`Os { code: 1 }`）になるため、測り直しは Claude Code の外のターミナルで行う
- zsh 固有構文には `ast-grep` の parser を確認できていない。検索・変換は `rg` と `shuck` に寄せる
