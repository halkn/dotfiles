# Repository Guidelines

## Project Structure & Module Organization

このリポジトリは個人用 dotfiles と周辺ツール設定を管理します。

| ディレクトリ / ファイル | 用途 |
|------------------------|------|
| `.config/nvim/` | Neovim 設定 |
| `.config/zsh/` | シェル起動設定 |
| `.config/herdr/` | ターミナル多重化設定（エージェント対応マルチプレクサ） |
| `.config/<tool>/` | その他ツール設定（gh, yamllint, yamlfmt 等） |
| `codex/` | OpenAI Codex 設定（`AGENTS.md` + `config.toml`） |
| `claude/` | Claude Code の dotfiles 実体（git 追跡対象、symlink で `~/.claude/` に繋がる） |
| `.claude/` | Claude Code のプロジェクト設定（git 追跡対象、`claude/` とは別物） |
| `.claude/rules/` | path-scoped ルール（例: `neovim.md` は `.config/nvim/**` 編集時のみロード） |
| `flake.nix` | Nix flake 定義（Mac: `aarch64-darwin` / WSL: `x86_64-linux`） |
| `home.nix` | home-manager モジュール本体（パッケージ・programs・ファイル配置） |
| `justfile` | 開発タスク定義（`just lint`, `just fmt` 等） |

`home-manager switch` が管理するファイル配置（`home.file` / `xdg.configFile`）:

| 配置先 | → 実体 |
|--------|--------|
| `~/.zshenv` | `~/.dotfiles/.zshenv` |
| `~/.claude/CLAUDE.md` | `~/.dotfiles/claude/CLAUDE.md` |
| `~/.claude/settings.json` | `~/.dotfiles/claude/settings.json` |
| `~/.claude/statusline-command.sh` | `~/.dotfiles/claude/statusline-command.sh` |
| `~/.claude/hooks/block-python.sh` | `~/.dotfiles/claude/hooks/block-python.sh` |
| `~/.claude/hooks/block-secret-read.sh` | `~/.dotfiles/claude/hooks/block-secret-read.sh` |
| `~/.config/nvim` | `~/.dotfiles/.config/nvim` |
| `~/.config/zsh` | `~/.dotfiles/.config/zsh` |

新規ファイルは対象ツールの近くに配置し、既存のディレクトリ命名に合わせてください。
Neovim 設計指針・変更手順は `.claude/rules/neovim.md`（`.config/nvim/**` 編集時に自動ロード）を参照。

## Build, Test, and Development Commands

- `home-manager switch --flake .#wsl`: WSL 環境へ適用します（初回セットアップ・更新）。
- `home-manager switch --flake .#mac`: Mac 環境へ適用します。
- `just`: 利用できる task を一覧します（`just --list`）。
- `just lint`: 通常の検証として diff 空白確認、`zsh` 構文確認、
  Markdown、formatter check、Neovim Lua diagnostics、起動確認を実行します。
- `just fmt`: Markdown、zsh、Neovim Lua を既定 formatter で整形します。
- `just fmt-check`: ファイルを書き換えずに整形を確認します。

更新系（エージェントは実行不可、ユーザーが手動実行）:

- zsh plugin 更新: `~/.local/share/zsh/plugins/` 以下の各ディレクトリで `git pull`
- Claude Code 更新: `claude update`
- system package 更新: ユーザーが個別に実行

## Coding Style & Naming Conventions

- **Shell**: `set -euo pipefail`、小文字の関数名、意味のある環境変数名を使う
- **Lua**: `lua/vimrc/` 配下で役割ごとに分け、プラグイン定義は `lua/vimrc/pack.lua` にまとめる
- **Nix**: `home.nix` に一元管理し、分割が必要な場合は `nix/` 配下にモジュールを置く
- **Markdown**: 短く実務的に書き、`rumdl` 準拠で整える
- **整形**: Shell・Lua ファイルは `just fmt` で整形する（`shfmt`・`stylua` は Nix 管理）

## Testing Guidelines

統一的な test harness はなく、変更対象ごとに最小の検証を実行してください。

| 変更対象 | 確認コマンド |
|----------|-------------|
| デフォルト（迷ったらこれ） | `just lint` |
| Neovim Lua | `just fmt && just lint` |
| Shell (zsh) | `just lint-zsh` |
| Markdown | `rumdl check <file>` |
| Shell 整形 | `shfmt -d <file>` |
| Nix 設定 | `home-manager switch --flake .#wsl`（または `#mac`） |

既存警告が残っている場合は対象ファイルに絞って確認してください。
対話的な変更は PR に手動確認内容を 1 行で添えてください。

## Commit & Pull Request Guidelines

**コミット:**

- prefix は小文字 conventional 形式: `fix:`, `add:`, `feat:`, `refactor:` など
- 短い英語要約を続け、1 つのツール・1 テーマに絞る（例: `fix: python lsp settings.`）

**PR:**

- 変更理由・影響範囲（`nvim`, `zsh`, `nix` 等）・確認手順を記載する
- 見た目が変わる場合のみスクリーンショットを付ける

## Security & Configuration Tips

- シークレット・トークン・端末固有の認証情報はコミットしない
- Nix 管理外のシークレット（gh トークン等）は `gh auth login` で別途設定する
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
