# Neovim の設計

対象は `.config/nvim/`。

## 原則

- 標準機能を軸にし、足りない部分だけを小さく補う
- 初期化の順序が読んで分かることを、起動の速さより優先する
- マシン固有の設定は、追跡外の `lua/local.lua` に置く（`init.lua` が最後に読む）

## plugin

- plugin manager は標準の `vim.pack` を使い、lazy load はしない
- 標準の plugin・provider は、使わないものを無効にする。treesitter の parser は、同梱のものと標準の syntax では足りない言語だけを足す
- plugin と treesitter の parser は Neovim 自身が導入・更新し、`nvim-pack-lock.json` で固定する。[mise.md](mise.md) の「インストールの入口は `mise bootstrap` だけ」の例外
- どの plugin を使うか、何を自作するか（statusline・[kago.nvim](https://github.com/halkn/kago.nvim)）は好みで決め、この doc の対象外

## keymap

- `<Leader>` にはエディタ全体の操作を、`<LocalLeader>` には今のバッファの言語に関わる操作（LSP・diagnostic）を置く

## LSP

- server の設定は `lsp/<name>.lua` に 1 server 1 ファイルで完結させ（数行の重複は共通化しない）、有効にするものを `lua/vimrc/lsp.lua` の `servers` で選ぶ。server 本体をどこで導入するかは [mise.md](mise.md) に従う
- server ごとに決まる調整は、その server の `lsp/<name>.lua` の `on_init` に置き、attach の順序に依存させない

## 検査とテスト

- エディタ上の診断・整形と食い違ったら、`lint` が走らせる `stylua --check` と `emmylua_check --warnings-as-errors` の結果に合わせる
- 診断の警告は、ファイルや範囲をまとめて外す `---@diagnostic disable` ではなく、型注釈で解く。解けない行だけを `---@diagnostic disable-next-line` か `--[[@as T]]` で外す
- `.emmyrc.json` で規則ごと外すのは、Neovim の設定の書き方と構造的に合わない規則だけにする
- テストは `.config/nvim/test/` に置く。ここが持つのは、設定のつなぎ込みと、組み合わせた状態での代表的な操作だけ。モジュール単体の回帰テストは `kago.nvim` 側に置く

## 決定と理由

- `.emmyrc.json` では `lua/` を `workspace.library` ではなく `workspaceRoots` に置く。library に入れると自分の設定が外部ライブラリ扱いになり、型エラーを入れても `emmylua_check` が「No issues found」を返す（emmylua_check 0.25.1）
