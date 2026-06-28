# Repository Guidelines

## Project Structure & Module Organization

このリポジトリは個人用 dotfiles と周辺ツール設定を管理します。

| ディレクトリ / ファイル | 用途 |
|------------------------|------|
| `.config/nvim/` | Neovim 設定 |
| `.config/zsh/` | シェル起動設定 |
| `.config/herdr/` | ターミナル多重化設定（エージェント対応マルチプレクサ） |
| `.config/<tool>/` | その他ツール設定（gh, git, starship 等） |
| `codex/` | OpenAI Codex 設定（`AGENTS.md` + `config.toml`） |
| `claude/` | Claude Code の dotfiles 実体（git 追跡対象、symlink で `~/.claude/` に繋がる） |
| `.claude/` | Claude Code のプロジェクト設定（git 追跡対象、`claude/` とは別物） |
| `.claude/rules/` | path-scoped ルール（例: `neovim.md` は `.config/nvim/**` 編集時のみロード） |
| `nix/` | Nix flake によるパッケージ管理（CLI・LSP・formatter 等） |
| `justfile` | 開発タスク定義 |
| `scripts/` | セットアップ用ヘルパースクリプト |

`just link` が作成する symlink:

| symlink | → 実体 |
|---------|--------|
| `~/.config` | `<dotfiles>/.config` |
| `~/.zshenv` | `<dotfiles>/.zshenv` |
| `~/.claude/<path>` | `<dotfiles>/claude/<path>`（`claude/` 配下を再帰的にリンク） |

`<dotfiles>` は justfile があるディレクトリ（`justfile_directory()`）に解決されます。

新規ファイルは対象ツールの近くに配置し、既存のディレクトリ命名に合わせてください。
Neovim 設計指針・変更手順は `.claude/rules/neovim.md`（`.config/nvim/**` 編集時に自動ロード）を参照。

## Build, Test, and Development Commands

- `just link`: dotfiles の symlink を `$HOME` に作成します（初回セットアップの第一歩）。
- `just setup`: `just link` + Nix パッケージインストール + uv / uv tools インストールを実行します。
- `just --list`: 利用できるレシピを一覧します。
- `just lint`: 通常の検証として diff 空白確認、`zsh` 構文確認、
  Markdown、formatter check、Neovim Lua diagnostics、起動確認を実行します。
- `just fmt`: Markdown、zsh、Neovim Lua を既定 formatter で整形します。
- `just fmt-check`: ファイルを書き換えずに Markdown、zsh、Neovim Lua の整形を確認します。

更新系（エージェントは実行不可、ユーザーが手動実行）:

- `just update`: Nix パッケージ更新・Claude Code 更新
- system package 更新: just タスクではなくユーザーが個別に実行

## Coding Style & Naming Conventions

- **Shell**: `set -euo pipefail`、小文字の関数名、意味のある環境変数名を使う
- **Lua**: `lua/vimrc/` 配下で役割ごとに分け、プラグイン定義は `lua/vimrc/pack.lua` にまとめる
- **Markdown**: 短く実務的に書き、`rumdl` 準拠で整える
- **整形**: Shell・Lua ファイルは `just fmt` で整形する（`shfmt`・`stylua` は Nix 管理）

## Testing Guidelines

統一的な test harness はなく、変更対象ごとに最小の検証を実行してください。

| 変更対象 | 確認コマンド |
|----------|-------------|
| デフォルト（迷ったらこれ） | `just lint` |
| Neovim Lua | `just fmt && just lint` |
| Shell (zsh) | `zsh -n .zshenv .config/zsh/.zshenv .config/zsh/.zshrc` |
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
- `.config/gh/` は secret として gitignore 対象 — 読み取りや変更はしない

## Machine-local Overrides（gitignore 対象）

端末固有の設定は以下のファイルへ記述する（追跡外）:

| ファイル | 用途 |
|----------|------|
| `.config/zsh/.zshenv.local` | 端末固有の環境変数 |
| `.config/zsh/.zshrc.local` | 端末固有のインタラクティブ設定 |
| `.config/git/config.local` | `user.name` / `user.email` など |
