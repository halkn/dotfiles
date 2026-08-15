---
paths:
  - ".config/nvim/**"
  - "**/*.lua"
---

# Neovim Design Principles

方針: 「標準機能を軸に、足りない部分だけを小さく補う」。手順と実測記録は `/neovim-lua` skill。

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
- ツールの宣言先は呼び出し元で決める。nvim が任意のディレクトリで呼ぶもの（`tree-sitter`・`shuck`・`ryl`・`rumdl`）は `.config/mise/config.toml`、このリポジトリの `mise run` からだけ呼ぶ Lua 系（`stylua`・`emmylua_check`・`emmylua_ls`）は `mise.toml`
- `mise.toml` のツールはこのリポジトリの外で PATH に載らない。`cmd` で PATH を直接参照する `lsp/emmylua_ls.lua` は他リポジトリで開いた Lua には attach しない（Lua はここでしか書かないため許容している）

**検査の維持:**

- `emmylua_check` の警告は 0 件を維持する（`--warnings-as-errors`）。`---@diagnostic disable` は使わず型注釈で解く
- `diagnostics.disable` に入れるのは、その診断がこの構成では常に無意味なときだけ（`operatorfunc` へ `v:lua` 経由で渡すための `_G` 代入）
- 静的検査は `vim.*` の遅延ロードモジュールに届かない。モジュールを足したら `test/smoke.lua` に代表操作を 1 つ足す
