---
paths:
  - ".config/nvim/**"
  - "**/*.lua"
---

# Neovim Design Principles

方針: 「標準機能を軸に、足りない部分だけを小さく補う」

**ファイル配置:**

- `lua/vimrc/` 配下で役割ごとに分ける。プラグイン定義は `lua/vimrc/pack.lua` にまとめる

**Plugin 制約:**

- `lazy load` は採用しない（初期化順序の明快さを優先）
- 追加条件: 責務が単一・標準機能では不足が明確・既存の操作感を崩さない
- plugin manager は Neovim 標準パッケージマネージャーを使用する
- UI 系（`statusline`、`picker`、`notify`）は自作を優先する

**LSP:**

- `g` は移動・ジャンプの prefix。ジャンプ系（definition・declaration・references・implementation・type_definition）を `g` に置き、rename・symbol・code action は `<F2>` と `<LocalLeader>` に置く
- ジャンプ系のうち標準が持つもの（`grr` `gri` `grt`）は標準をそのまま使い、buffer-local に張り直さない。`gr` を buffer-local に張ると `gr*` 系の入力が全て 'timeoutlen' 待ちになる（`:help map-nowait`）。自前で張るのは標準に無い `gd` `gD` だけ
- 標準の非ジャンプ既定（`grn` `gra` `gO` `grx`）は消さずに残す。`<F2>` / `<LocalLeader>*` と二重になるが、他環境との差分を小さく保つ
- `LspAttach` で張るキーマップは `client:supports_method()` で分岐する。server が持たない機能のキーが残るとエラーになる
- `LspAttach` で作った buffer-local の autocmd は `LspDetach` で外す。augroup はバッファごとに作らず単一 augroup + `buffer` 指定にする
- server 単位で決まる capability の調整（ruff の hover 無効化など）は `lsp/<name>.lua` の `on_init` に置く。`LspAttach` で他 client の有無を見る形は attach 順に依存して落ちる
- `lsp/<name>.lua` は 1 サーバー 1 ファイルで自己完結させる。数行の重複は共通モジュール化しない
- `single_file_support` は 0.11 以降の `vim.lsp.Config` に無い（相当するのは既定 `false` の `workspace_required`）。`vim.lsp.config()` は呼び出し時に検証しないので、未知キーも型不一致も黙って通る

**ツールチェーン:**

- formatter: `stylua` が正。editor 内では `emmylua_ls` が external formatter として呼び出す
- diagnostics: `emmylua_check` と editor 内の `emmylua_ls` が正
- ツールの宣言先は呼び出し元で決める。nvim が任意のディレクトリで呼ぶもの（parser をビルドする `tree-sitter`）は `.config/mise/config.toml`、このリポジトリの `mise run` からだけ呼ぶもの（`stylua`・`emmylua_check`・`emmylua_ls`・`shuck`）は `mise.toml`
- `mise.toml` のツールはこのリポジトリの外で PATH に載らない。`cmd` で PATH を直接参照する LSP（`lsp/emmylua_ls.lua`・`lsp/shuck.lua`）は他リポジトリでは起動しない。他でも使うなら `.config/mise/config.toml` へ移す

**静的解析の境界:**

- `.emmyrc.json` の `workspace.library` は外部コード専用。`lua/` は `workspaceRoots` に置く。library に入れると自分の設定が「外部ライブラリ」扱いになり、診断が 1 件も出ないまま lint が緑になる
- `emmylua_check` は `vim.hl` / `vim.pack` のような遅延ロードモジュールのフィールドを検証しない。存在しない `vim.*` API はここには出ないので、実行時検査（`test/smoke.lua`）が受け持つ
- 警告は 0 件を維持する（`--warnings-as-errors`）。推論限界に見えるものの大半は型注釈で解ける: module-local の state テーブルには `---@class` + `---@field x integer?` を、`M.config` には `---@class` + `---@type` と `M.setup` の `---@param opts <Config>?` を付ける
- ヘルパー関数越しの nil チェックはナローイングされない。値をローカルに束縛してその場で `if x and ...` する。`number` を `integer` 引数へ渡すところは `math.floor()` を挟む
- 型注釈で解けないときだけ `--[[@as T]]` を使い、なぜその検査が成立しないのかをコメントに書く（現行 4 箇所: `getreg()` の多重シグネチャ・`make_range_params()` に無い `context`・`vim.iter` の `@operator call`・blink.cmp の `*ConfigPartial`）。`---@diagnostic disable` は使わない
- `diagnostics.disable` に入れるのは、その診断がこの構成では常に無意味なときだけ（`operatorfunc` へ `v:lua` 経由で渡すための `_G` 代入）

**実行時検査（`test/smoke.lua`）:**

- `lsp/*.lua` は `vim.lsp.enable()` が対象 filetype を開くまで読まないので、`nvim_get_runtime_file('lsp/*.lua')` で全件 `dofile` して読み込みエラーを表に出す
- autocmd・keymap を headless で実際に発火させる。autocmd 内のエラーは Neovim が握り潰して `:messages` に流すだけで例外にならないため、pcall ではなく messages を照合して判定する
- モジュールを足したら代表操作を 1 つ足す。プロセスを起動できない環境では terminal 系が自動でスキップされる

**変更時の手順:**

1. `mise run fmt` で整形（`stylua` + `shuck`）
1. `mise run lint` で確認（`stylua --check`・`emmylua_check`・`test/smoke.lua`）
1. tools がない場合は先に `mise install` を実行する（lockfile 固定のまま導入される）
