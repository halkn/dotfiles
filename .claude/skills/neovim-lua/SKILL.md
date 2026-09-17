---
description: このリポジトリの Neovim 設定（.config/nvim 配下の Lua・lsp/*.lua・test/smoke.lua・.emmyrc.json）を変更するときの検証手順。emmylua_check の警告を型注釈で解く、smoke test に検査を足す、静的検査の届かない範囲を確かめる、といった作業で使う。
---

# Neovim Lua の検証

判断基準そのものは `.claude/rules/neovim.md`。ここに置くのは、その基準を満たすための手順。

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

## 検査の届かない範囲

- `.emmyrc.json` の `workspace.library` に `lua/` を入れると自分の設定が「外部ライブラリ」扱いになり、診断が 1 件も出ないまま lint が緑になる（`workspaceRoots` に置くこと）
- 遅延ロードされる `vim.*` のフィールドは静的検査に出ない。存在しない API・LSP 設定の未知キーは lint を通るので、キー名と既定値は Neovim の docs で確認してから書き、実行時検査で受ける

## test/smoke.lua に検査を足す

- `lsp/*.lua` は `vim.lsp.enable()` が対象 filetype を開くまで読まれない。`nvim_get_runtime_file('lsp/*.lua')` で全件 `dofile` して読み込みエラーを表に出している
- autocmd・keymap は headless で実際に発火させる。autocmd 内のエラーは Neovim が握り潰して `:messages` に流すだけで例外にならないため、pcall ではなく messages を照合して判定する
- プロセスを起動できない環境では terminal 系が自動でスキップされる
