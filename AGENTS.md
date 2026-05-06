# Repository Guidelines

## Project Structure & Module Organization

このリポジトリは個人用 dotfiles と周辺ツール設定を管理します。
主要な設定は `.config/` 配下にあり、`.config/nvim/` は Neovim、
`.config/zsh/` はシェル起動、`.config/tmux/` と `.config/zellij/` は
ターミナル多重化、`.config/ptm/` はツール定義です。
AI アシスタント設定は `codex/` と `claude/` にあります。
新規ファイルは対象ツールの近くに配置し、既存のディレクトリ命名に合わせてください。

## Build, Test, and Development Commands

- `just`: 利用できる task を一覧します。
- `just setup`: symlink 作成、`apt` 更新、`ptm install`、Neovim managed tools install を実行します。
- `just lint`: 通常の検証として diff 空白確認、`zsh` 構文確認、Neovim Lua diagnostics、起動確認を実行します。
- `just fmt`: Neovim Lua を managed `stylua` で整形します。
- `just update`: `apt`、`ptm` 管理ツール、Neovim managed tools を更新します。
- `just status`: 意図した dotfiles だけが変更されているか確認します。

`just setup` と `just update` は system package や symlink に触れるため、
必要性を説明し、ユーザーの了承がある場合に実行してください。

## Coding Style & Naming Conventions

Shell は `set -euo pipefail`、小文字の関数名、意味のある環境変数名を基本とします。
Lua 設定は `.config/nvim/lua/vimrc/` 配下で役割ごとに分け、
プラグイン定義は `.config/nvim/lua/plugins/` に機能単位で分割します。
Markdown は短く実務的に書き、`rumdl` を前提に整えます。
Shell ファイルと Lua ファイルは、グローバル PATH の formatter ではなく
`just fmt` が使う Neovim managed tools で整形してください。

## Neovim Design Principles

Neovim 設定は「標準機能を軸に、足りない部分だけを小さく補う」方針で保ちます。
初期化順序は `options`、`diagnostics`、`keymaps`、`autocmds`、`lsp`、`modules`、`plugins` を基本とします。
`options` には起動時 option と provider 設定、`diagnostics` には `vim.diagnostic.config()`、
`keymaps` には LSP 非依存の global keymap、`autocmds` には LSP 非依存の autocmd を置いてください。
`lsp/lang/registry.lua` には LSP server、efm backend、formatter の言語別静的定義、
`lsp/lang/schema.lua` には LuaLS 用の型境界、
`lsp/lang/init.lua` には registry から派生値を返す query API を置いてください。
`lsp/` には LSP attach、LSP keymap、format-on-save などの共通実行時処理を置き、
`.config/nvim/lsp/*.lua` には Neovim 公式形式の server config を置いてください。
`modules` には自作の UI や操作改善、`plugins` には外部依存の薄い機能別プラグインを置いてください。
定番プラグインで置き換える前に、Neovim 組み込み API や既存 module で十分かを先に検討します。

plugin は必要最小限に保ち、機能追加のために安易に数を増やさないでください。
追加する場合は、責務が単一であること、標準機能では不足が明確であること、
既存の操作感を崩さないことを条件にします。
`lazy load` は原則として採用せず、構成の単純さと初期化順序の明快さを優先してください。

plugin manager は Neovim 標準を優先します。
標準パッケージマネージャーで十分な機能がある限り、外部 manager は増やしません。
将来 Neovim 標準で置き換え可能な機能が入った場合は、既存 plugin の置き換えを検討してください。
UI 系は `statusline`、`picker`、`notify` のように自作を優先します。
LSP や formatter は言語別設定を分離して管理してください。
責務の重複は避け、特に format、lint、diagnostics、keymap は担当層を明確にしてください。

Lua formatter は Neovim managed tools の `stylua` を正としてください。
diagnostics は managed tools の `lua-language-server --check` と
editor 内の `luals` を正とします。
`luals` の built-in formatter を再び主担当に戻さないでください。
Neovim 内で使う LSP server と efm backend tool は
`:NvimToolsInstall` / `:NvimToolsUpdate` で管理し、グローバル PATH には通しません。

Neovim Lua を変更したときは、通常は `just fmt` で整形し、`just lint` で確認します。
`just lint` は `stylua --check`、`lua-language-server --check`、
`nvim --headless -i NONE '+quitall'` をまとめて確認します。
managed tools がない場合は先に `just setup`、更新したい場合は `just update` を実行します。
差分が広い場合は、意味変更と整形-only の変更を区別して確認してください。
`statusline` や `vim` global のような Neovim 固有 API は、
`.config/nvim/.luarc.json` の前提を崩さないように扱ってください。

## Testing Guidelines

統一的な test harness はないため、変更対象ごとに確認します。

- 通常: `just lint` を実行します。
- Neovim Lua: 変更後は `just fmt` と `just lint` を実行します。
- Shell: `zsh` 変更時は `just lint` の `zsh -n` 確認を通します。
- 文書と整形: `*.md` は `rumdl`、shell 系ファイルは `shfmt` で確認します。
  既存警告が残っている場合は、対象ファイルに絞って確認してください。

対話的な変更は PR に手動確認内容を 1 行で添えてください。

## Commit & Pull Request Guidelines

最近の履歴では `fix: python lsp settings.` や `add: codex settings.` のような
短い conventional 形式が使われています。
`fix:`, `add:`, `feat:` などの小文字 prefix に短い英語要約を続け、
1 つのツールまたは 1 つのテーマに絞ってコミットしてください。
PR では変更理由、影響範囲 (`nvim`, `zsh`, `codex` など)、必要なら確認手順を明記します。
見た目が変わる場合のみスクリーンショットを付けてください。

## Security & Configuration Tips

シークレット、トークン、端末固有の認証情報はコミットしないでください。
symlink や path は可能な限りポータブルに保ち、
このリポジトリにローカル専用の状態ファイルを書き込まないでください。
