# Repository Guidelines

## Project Structure & Module Organization

このリポジトリは個人用 dotfiles と周辺ツール設定を管理します。

| ディレクトリ / ファイル | 用途 |
|------------------------|------|
| `.config/nvim/` | Neovim 設定 |
| `.config/zsh/` | シェル起動設定 |
| `.config/tmux/` | ターミナル多重化設定 |
| `.config/<tool>/` | その他ツール設定（gh, git, starship 等） |
| `codex/` | OpenAI Codex 設定（`AGENTS.md` + `config.toml`） |
| `claude/` | Claude Code 設定（`CLAUDE.md` + `settings.json` + `statusline-command.sh`） |
| `.config/mise/config.toml` | mise 管理ツールのバージョン定義（LSP server・formatter 等） |
| `justfile` | 開発タスク定義 |

`just link` が作成する symlink:

| symlink | → 実体 |
|---------|--------|
| `~/.config` | `~/.dotfiles/.config` |
| `~/.zshenv` | `~/.dotfiles/.zshenv` |
| `~/.claude/CLAUDE.md` | `~/.dotfiles/claude/CLAUDE.md` |
| `~/.claude/settings.json` | `~/.dotfiles/claude/settings.json` |

新規ファイルは対象ツールの近くに配置し、既存のディレクトリ命名に合わせてください。

## Build, Test, and Development Commands

- `just link`: dotfiles の symlink を `$HOME` に作成します（初回セットアップの第一歩）。
- `just setup`: `just link` + mise インストール + ツールインストール + zsh plugin clone + Claude Code インストールを実行します。
- `just`: 利用できる task を一覧します。
- `just lint`: 通常の検証として diff 空白確認、`zsh` 構文確認、
  Markdown、formatter check、Neovim Lua diagnostics、起動確認を実行します。
- `just fmt`: Markdown、zsh、Neovim Lua を既定 formatter で整形します。
- `just fmt-check`: ファイルを書き換えずに Markdown、zsh、Neovim Lua の整形を確認します。
- `just update`: mise tools 更新・zsh plugin 更新・Claude Code 更新を実行します。

Agent は `just update` を自律実行せず、明示依頼がある場合だけ実行してください。
system package 更新が必要な場合は、just task ではなくユーザーが個別に実行します。

## Coding Style & Naming Conventions

- **Shell**: `set -euo pipefail`、小文字の関数名、意味のある環境変数名を使う
- **Lua**: `lua/vimrc/` 配下で役割ごとに分け、プラグイン定義は `lua/plugins/` に機能単位で分割する
- **Markdown**: 短く実務的に書き、`rumdl` 準拠で整える
- **整形**: Shell・Lua ファイルは `just fmt` で整形する（`shfmt`・`stylua` は Nix 管理）

## Neovim Design Principles

方針: 「標準機能を軸に、足りない部分だけを小さく補う」

**初期化順序** (`lua/vimrc/` 内): `options` → `diagnostics` → `keymaps` → `autocmds` → `lsp` → `modules` → `plugins`

**ファイル配置ルール:**

| パス | 役割 |
|------|------|
| `lua/vimrc/options.lua` | 起動時 option と provider 設定 |
| `lua/vimrc/diagnostics.lua` | `vim.diagnostic.config()` |
| `lua/vimrc/keymaps.lua` | LSP 非依存の global keymap |
| `lua/vimrc/autocmds.lua` | LSP 非依存の autocmd |
| `lua/vimrc/lsp/lang/registry.lua` | LSP server・efm backend・formatter の言語別静的定義 |
| `lua/vimrc/lsp/lang/schema.lua` | LuaLS 用の型境界 |
| `lua/vimrc/lsp/lang/init.lua` | registry から派生値を返す query API |
| `lua/vimrc/lsp/` | LSP attach・keymap・format-on-save などの共通実行時処理 |
| `lsp/*.lua` | Neovim 公式形式の server config（0.11+ 形式） |
| `lua/vimrc/modules/` | 自作 UI・操作改善 |
| `lua/plugins/` | 外部依存の機能別プラグイン定義 |

**Plugin 制約:**
- `lazy load` は採用しない（初期化順序の明快さを優先）
- 追加条件: 責務が単一・標準機能では不足が明確・既存の操作感を崩さない
- plugin manager は Neovim 標準パッケージマネージャーを使用する
- UI 系（`statusline`、`picker`、`notify`）は自作を優先する

**ツールチェーン:**
- formatter: `stylua` が正。`luals` の built-in formatter を主担当に戻さないこと
- diagnostics: `lua-language-server --check` と editor 内の `luals` が正
- LSP server・efm backend tool は `flake.nix` で管理し PATH 経由で参照する

**変更時の手順:**
1. `just fmt` で整形（`stylua` + `shfmt`）
2. `just lint` で確認（`stylua --check`・`lua-language-server --check`・起動確認）
3. tools がない場合は先に `just setup` を実行する
4. `.config/nvim/.luarc.json` の前提（`statusline`・`vim` global 等）を崩さないこと

## Testing Guidelines

統一的な test harness はなく、変更対象ごとに最小の検証を実行してください。

| 変更対象 | 確認コマンド |
|----------|-------------|
| 通常 | `just lint` |
| Neovim Lua | `just fmt && just lint` |
| Shell (zsh) | `just lint-zsh`（または `just lint` 内の `zsh -n`） |
| Markdown | `rumdl check <file>` |
| Shell 整形 | `shfmt -d <file>` |

既存警告が残っている場合は対象ファイルに絞って確認してください。
対話的な変更は PR に手動確認内容を 1 行で添えてください。

## Commit & Pull Request Guidelines

**コミット:**
- prefix は小文字 conventional 形式: `fix:`, `add:`, `feat:`, `refactor:` など
- 短い英語要約を続け、1 つのツール・1 テーマに絞る（例: `fix: python lsp settings.`）

**PR:**
- 変更理由・影響範囲（`nvim`, `zsh`, `codex` 等）・確認手順を記載する
- 見た目が変わる場合のみスクリーンショットを付ける

## Security & Configuration Tips

- シークレット・トークン・端末固有の認証情報はコミットしない
- symlink と path は可能な限りポータブルに保つ
- ローカル専用の状態ファイルをこのリポジトリに書き込まない
