# Repository Guidelines

個人用 dotfiles。symlink 配置・mise ツール・OS パッケージ・ログインシェルは全て `mise.toml` の宣言を single source of truth として `mise bootstrap` が適用する。セットアップの全体像は `README.md` を参照。

## Non-obvious layout

- `claude/` が Claude Code 設定の実体。`~/.claude/` へはディレクトリ単位ではなく `mise.toml` の `[dotfiles]` によるファイル単位の symlink なので、`claude/` に新規ファイルを足しても宣言しない限り配置されない。`.claude/` はこのリポジトリ自身のプロジェクト設定で別物
- `.config/mise/config.toml` は `~/.config/mise/config.toml` としても読まれる。ここへの変更はリポジトリ外の全プロジェクトに影響する
- `.config/zsh/worktree.zsh`（`wt`）は `.zshrc` だけでなく `.config/herdr/herdr-picker.sh` からも source される。worktree の一覧・削除ロジックはここに集約し、picker 側で再実装しない
- zsh の `path` は PATH の配列。worktree のパスを入れる変数に `local path` を使うと関数内で PATH が消える（`wt_path` を使う）
- `.claude/rules/` の path-scoped ルールを `~/.claude/rules/` へ移さない。`paths:`/`globs:` 指定が user-level では読み込まれない（anthropics/claude-code#19377, #21858）。全プロジェクト共通のルールは `claude/CLAUDE.md` に直接書く

## Verification

- 変更後は `mise run lint`。Neovim Lua を触った場合は先に `mise run fmt`
- 既存警告が多い場合は対象ファイルに絞る（`rumdl check <file>`、`shuck format --check <file>`）
- 更新系（`mise run setup` / `sync` / `update`）はユーザーが手動実行する
- `mise bootstrap --force-dotfiles` は競合ファイルをバックアップなしで上書きする。提案する前に `mise bootstrap --dry-run` で差分を示す
- 対話操作でしか確認できない変更は、PR に手動確認の内容を 1 行添える

## Conventions

- macOS に GNU `timeout` は無い。timeout が要る script は `timeout` / `gtimeout` / 直接実行の順にフォールバックする（`claude/file-suggestion.sh` の `run_with_timeout` を踏襲する）
- 整形は `mise run fmt` に任せる（`shuck`・`stylua`・`rumdl`）
- commit: 小文字 conventional prefix（`fix:` `add:` `feat:` `refactor:`）+ 短い英語要約。1 コミット 1 ツール・1 テーマ（例: `fix: python lsp settings.`）
- PR: 変更理由・影響範囲（`nvim`・`zsh`・`claude` 等）・確認手順を書く

## Machine-local overrides（gitignore 対象）

端末固有の設定は追跡外の `*.local` ファイルに置く: `.config/zsh/.zshenv.local`（環境変数）、`.config/zsh/.zshrc.local`（インタラクティブ）、`.config/mise/config.local.toml`（global mise の `[env]` / tool / setting override）、`mise.local.toml`（このリポジトリの mise override）、`.config/git/config.local`（`user.name` / `user.email`）。
