# Neovim の設計

方針: 標準機能を軸にし、足りない部分だけを小さく補う。

## 構成

- plugin manager は標準の `vim.pack` を使い、plugin は `lua/vimrc/pack.lua` に定義する。lazy load はしない。初期化の順序が分かりやすいことを、起動の速さより優先する
- plugin を足すのは、責務が 1 つで、標準機能では足りないことがはっきりしていて、既存の操作感を崩さないときだけにする
- UI 系は自作する。statusline は `lua/vimrc/statusline.lua` に、picker・notify・input などは [kago.nvim](https://github.com/halkn/kago.nvim) に置く

## LSP

- server を足すときは `lsp/<name>.lua` を作り、`lua/vimrc/lsp.lua` の `servers` に登録する。server 本体をどこで導入するかは [mise.md](mise.md) に従う
- `lsp/<name>.lua` は 1 server 1 ファイルで完結させる。数行の重複は共通化しない
- server ごとに決まる調整は、その server の `lsp/<name>.lua` の `on_init` に置く。`LspAttach` で他の client の有無を見ると、attach の順序次第で壊れる

## 検査とテスト

- 整形は `stylua`、診断は `emmylua_check` を正とする。`emmylua_ls` は `mise.toml` の toolchain を使うので、このリポジトリの外の Lua には attach しない（Lua はここでしか書かないので、それで足りる）
- `emmylua_check` の警告は 0 件を保つ。ファイルや範囲をまとめて外す `---@diagnostic disable` は使わず、型注釈で解く。解けない行だけを `---@diagnostic disable-next-line` か `--[[@as T]]` で外す
- `.emmyrc.json` では `lua/` を `workspace.library` ではなく `workspaceRoots` に置く。library に入れると自分の設定が外部ライブラリ扱いになり、診断が 1 件も出ないまま lint が通ってしまう
- テストは `.config/nvim/test/` に置く。ここが持つのは、設定のつなぎ込みと、組み合わせた状態での代表的な操作だけ。モジュール単体の回帰テストは `kago.nvim` 側に置く
