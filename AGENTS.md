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
| `.claude/rules/` | path-scoped ルール（例: `neovim.md` は `.config/nvim/**` 編集時のみロード）。`~/.claude/rules/` への user-level 分割はしない — `paths:`/`globs:` 指定が user-level では読み込まれない既知の不具合があるため（anthropics/claude-code#19377, #21858）。全プロジェクト共通のルールは `claude/CLAUDE.md` に直接書く |
| `.codex/` | Codex のプロジェクト設定（git 追跡対象、`codex/` とは別物） |
| `.config/mise/` | mise によるツール管理（CLI・LSP・formatter 等の共有設定 + `mise.lock`）。`config.toml` は symlink により `~/.config/mise/config.toml` としても読まれるため、このリポジトリ外の全プロジェクトに影響するグローバル mise 設定を兼ねる |
| `mise.toml` | dotfiles 固有の Neovim ツール + セットアップ宣言（`[dotfiles]` / `[bootstrap.repos]` / `[bootstrap.packages]` / `[bootstrap.user]`）+ 開発タスク定義 |
| `mise-tasks/` | 複数行スクリプトの file task（`#MISE` コメントでメタデータ宣言、例: `lint/luals` → `lint:luals`） |
| `mise.lock` | `mise.toml` の tools のバージョン・checksum 固定（`mise run update` で更新） |

symlink 配置は `mise bootstrap` が `mise.toml` の `[dotfiles]` セクション（single source of truth）から宣言的に適用します。対象は `~/.config`・`~/.zshenv`・`~/.claude/` 配下（settings.json, CLAUDE.md, statusline-command.sh, file-suggestion.sh, hooks/*）です。source は `mise.toml` があるディレクトリ（mise の `{{config_root}}`）基準で解決されます。

zsh プラグイン（zsh-autosuggestions, fast-syntax-highlighting）は `[bootstrap.repos]` で `~/.local/share/zsh/plugins/` に clone/update されます。

OS パッケージは `[bootstrap.packages]` に `"apt:<pkg>"` / `"brew:<pkg>"` 形式で宣言され、`apt:` は Linux、`brew:` は macOS でのみ不足分がインストールされます（それ以外の OS では自動スキップ）。`apt:` 以外に `brew-cask:` / `dnf:` / `pacman:` / `apk:` / `mas:` の prefix にも対応しています。git/curl は macOS でも `brew:` エントリとして宣言されていますが、zsh/unzip/bubblewrap/socat は macOS では不要（zsh 標準搭載、Claude Code サンドボックスが macOS では Seatbelt を使うため）で `apt:` のみです。ログインシェルは `[bootstrap.user]` の `login_shell = "/bin/zsh"` から冪等に適用されます（`/etc/shells` 登録 + `chsh`）。

新規ファイルは対象ツールの近くに配置し、既存のディレクトリ命名に合わせてください。
Neovim 設計指針・変更手順は `.claude/rules/neovim.md`（`.config/nvim/**` 編集時に自動ロード）を参照。

## Build, Test, and Development Commands

- `mise run setup`（= `mise bootstrap --yes`）: OS パッケージ導入（Linux は apt、macOS は自動スキップ、sudo は不足時のみ）+ zsh プラグイン clone + dotfiles symlink 配置 + ログインシェル設定 + mise ツールインストール + Claude Code インストールを冪等に実行します。初回実行時は `mise trust` が必要です。
- `mise bootstrap --dry-run` / `mise bootstrap status`: 適用内容の事前確認・状態確認ができます。
- 新規マシンで `~/.config` などが実ディレクトリとして既に存在する場合、mise は管理外ファイルを上書きしません。`mise bootstrap --force-dotfiles` は競合ファイルを**バックアップなしでその場に上書き**するため、実行前に手動でバックアップしてください（例: `mv ~/.config ~/.config.bak`）。
- `mise tasks`: 利用できるタスクを一覧します。
- `mise run lint`: 通常の検証として diff 空白確認、`zsh` 構文確認、
  Markdown、formatter check、Neovim Lua diagnostics、起動確認を実行します。
- `mise run fmt`: Markdown、zsh、Neovim Lua を既定 formatter で整形します（`mise.toml` 自体のキー整形も含む）。
- `mise run fmt-check`: ファイルを書き換えずに Markdown、zsh、Neovim Lua の整形を確認します。

更新系（エージェントは実行不可、ユーザーが手動実行）:

- `mise run update`: mise ツール更新（`mise.lock` も更新される）・zsh プラグイン更新・Claude Code 更新。更新後は `mise.lock` / `.config/mise/mise.lock` の差分をコミットする
- system package 更新: `[bootstrap.packages]` 宣言分は `mise bootstrap packages upgrade`（ユーザー手動実行、sudo あり得る）、それ以外は従来どおりユーザーが個別に実行

## Coding Style & Naming Conventions

- **Shell**: `set -euo pipefail`、小文字の関数名、意味のある環境変数名を使う
- **Lua**: `lua/vimrc/` 配下で役割ごとに分け、プラグイン定義は `lua/vimrc/pack.lua` にまとめる
- **Markdown**: 短く実務的に書き、`rumdl` 準拠で整える
- **整形**: Shell・Lua ファイルは `mise run fmt` で整形する（`shfmt`・`stylua` は mise 管理）

## Testing Guidelines

統一的な test harness はなく、変更対象ごとに最小の検証を実行してください。

| 変更対象 | 確認コマンド |
|----------|-------------|
| デフォルト（迷ったらこれ） | `mise run lint` |
| Neovim Lua | `mise run fmt && mise run lint` |
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
- `claude/settings.json` の `sandbox.credentials.envVars` はワイルドカード非対応の手動列挙リスト。新しいシークレット系 CLI ツールを導入したら対応する環境変数名をここに追加する。補完として `env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB=1` が Anthropic・クラウドプロバイダ系の認証情報を全サブプロセスから strip する
- `claude/settings.json` の `sandbox.credentials.files` は `~/.config/gh`（gh の token ファイル）のサンドボックス内読み取りを OS レベルで deny する。`gh` 本体は `excludedCommands` でサンドボックス外実行のため影響しない。新しいシークレット系 CLI の認証ファイルを導入したらここに追加する（ただし az のようにサンドボックス内で token cache を読む必要がある CLI のディレクトリは deny しない）
- `claude/settings.json` の `autoMode.environment` に社内・仕事用のインフラ情報（組織名・内部ホスト名等）を書かない。仕事用の trusted infrastructure は各リポジトリの `.claude/settings.local.json`（gitignore 対象）に記述する — autoMode はそこからも読まれる

## Machine-local Overrides（gitignore 対象）

端末固有の設定は以下のファイルへ記述する（追跡外）:

| ファイル | 用途 |
|----------|------|
| `.config/zsh/.zshenv.local` | 端末固有の環境変数 |
| `.config/zsh/.zshrc.local` | 端末固有のインタラクティブ設定 |
| `.config/git/config.local` | `user.name` / `user.email` など |
