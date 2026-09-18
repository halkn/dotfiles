---
description: このリポジトリの Neovim 設定を変更するときに使う。設計方針・検証手順・実測記録を持つ。対象は .config/nvim 配下の Lua・lsp/*.lua・test/smoke.lua・.emmyrc.json。plugin やキーマップを足すか判断する、emmylua_check の警告を型注釈で解く、smoke test に検査を足す、vim.lsp.Config のキーを調べる、といった作業。
---

# Neovim Lua

方針: 「標準機能を軸に、足りない部分だけを小さく補う」。

## 設計方針

**構成:**

- `lua/vimrc/` 配下で役割ごとに分ける。プラグイン定義は `lua/vimrc/pack.lua` にまとめる
- `lazy load` は採用しない（初期化順序の明快さを優先）
- plugin manager は Neovim 標準パッケージマネージャーを使用する
- plugin の追加条件: 責務が単一・標準機能では不足が明確・既存の操作感を崩さない。UI 系（`statusline`、`picker`、`notify`）は自作を優先する

**LSP:**

- `g` は移動・ジャンプの prefix。ジャンプ系（definition・declaration・references・implementation・type_definition）を `g` に置き、rename・symbol・code action は `<F2>` と `<LocalLeader>` に置く
- ジャンプ系のうち標準が持つもの（`grr` `gri` `grt`）は標準をそのまま使い、buffer-local に張り直さない。`gr` を buffer-local に張ると `gr*` 系の入力が全て 'timeoutlen' 待ちになる（`:help map-nowait`）。自前で張るのは標準に無い `gd` `gD` だけ
- 標準の非ジャンプ既定（`grn` `gra` `gO` `grx`）は消さずに残す。`<F2>` / `<LocalLeader>*` と二重になるが、他環境との差分を小さく保つ
- `LspAttach` で張るキーマップは `client:supports_method()` で分岐する。server が持たない機能のキーが残るとエラーになる
- `LspAttach` で作った buffer-local の autocmd は `LspDetach` で外す。augroup はバッファごとに作らず単一 augroup + `buffer` 指定にする
- server 単位で決まる capability の調整（ruff の hover 無効化など）は `lsp/<name>.lua` の `on_init` に置く。`LspAttach` で他 client の有無を見る形は attach 順に依存して落ちる
- `lsp/<name>.lua` は 1 サーバー 1 ファイルで自己完結させる。数行の重複は共通モジュール化しない

**ツールチェーン:**

- formatter は `stylua`、diagnostics は `emmylua_check` が正。editor 内では `emmylua_ls` が両方を担う
- ツールの宣言先は呼び出し元で決める（README の Tool Manager）。nvim が任意のディレクトリで呼ぶ `tree-sitter`・`shuck`・`ryl`・`rumdl` は `.config/mise/config.toml`、Lua 系は `mise.toml`
- `mise.toml` のツールはこのリポジトリの外で PATH に載らない。`cmd` で PATH を直接参照する `lsp/emmylua_ls.lua` は他リポジトリで開いた Lua には attach しない（Lua はここでしか書かないため許容している）

**検査の維持:**

- `emmylua_check` の警告は 0 件を維持する（`--warnings-as-errors`）。`---@diagnostic disable` は使わず型注釈で解く
- `diagnostics.disable` に入れるのは、その診断がこの構成では常に無意味なときだけ（`operatorfunc` へ `v:lua` 経由で渡すための `_G` 代入）
- 静的検査は `vim.*` の遅延ロードモジュールに届かない。`test/smoke.lua` が持つのは wiring と integration の代表操作で、module 単体の回帰は `kago.nvim` 側に置く

## 手順

1. `mise run fmt` で整形する（`stylua` + `shuck`）
1. `mise run lint` で確認する（`stylua --check`・`emmylua_check --warnings-as-errors`・`test/smoke.lua`）
1. module 固有の回帰（Explorer / Picker / Input / Notify / Terminal / editing 系）を単独確認するときは `~/repos/github.com/halkn/kago.nvim` で `mise run check` を実行する
1. ツールが無い場合は先に `mise install`。`stylua` / `emmylua_check` / `emmylua_ls` はこのリポジトリの `mise.toml` にあるので、他のリポジトリでは PATH に載らない

## emmylua_check の警告を解く

推論限界に見えるものの大半は型注釈で解ける。

- module-local の state テーブル: `---@class` + `---@field x integer?`
- `M.config`: `---@class` + `---@type`、および `M.setup` の `---@param opts <Config>?`
- ヘルパー関数越しの nil チェックはナローイングされない。値をローカルに束縛してその場で `if x and ...` する
- `number` を `integer` 引数へ渡すところは `math.floor()` を挟む

型注釈で解けないときだけ `--[[@as T]]` を使い、なぜその検査が成立しないのかをコメントに書く。

## 検査の届かない範囲（emmylua_check 0.25.0 / Neovim 0.12.4 で確認）

- `vim.hl` / `vim.pack` のような遅延ロードモジュールのフィールドは検証されない。存在しない `vim.*` API はこの検査に出ないので、実行時検査が受け持つ
- `vim.lsp.config()` は呼び出し時に検証しない。未知キーも型不一致も黙って通る。`single_file_support` は 0.11 以降の `vim.lsp.Config` に無く、相当するのは既定 `false` の `workspace_required`
- `.emmyrc.json` の `workspace.library` に `lua/` を入れると自分の設定が「外部ライブラリ」扱いになり、診断が 1 件も出ないまま lint が緑になる（`workspaceRoots` に置くこと）

## test/smoke.lua に検査を足す

- `lsp/*.lua` は `vim.lsp.enable()` が対象 filetype を開くまで読まれない。`nvim_get_runtime_file('lsp/*.lua')` で全件 `dofile` して読み込みエラーを表に出している
- autocmd・keymap は headless で実際に発火させる。autocmd 内のエラーは Neovim が握り潰して `:messages` に流すだけで例外にならないため、pcall ではなく messages を照合して判定する
- プロセスを起動できない環境では terminal 系が自動でスキップされる
