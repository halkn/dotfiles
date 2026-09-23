# Repository Guidelines

個人用 dotfiles。ディレクトリ構成とセットアップは `README.md`、設計方針は `docs/` にある。ファイルを変更する前に、`docs/README.md` の対応表で該当する doc を読む。

## Verification

- 変更後は `mise run fmt` → `mise run lint`。`lint` は整形チェック・各言語の検査・テストを全て含む
- 既存の警告が多いときは対象ファイルに絞る（`rumdl check <file>`、`shuck format --check <file>`）
- ツールが無ければ先に `mise install`
- `mise run sync` / `update` と `mise bootstrap` はユーザーが手で実行する

## Conventions

- 設計判断を足したり変えたりしたら、同じ変更で `docs/` を直す。何をどこに書くかは `docs/README.md` に従う
- コードコメントは英語で書く。識別子やコマンド名と同じ語彙で書けるため。ユーザーに表示される文字列（hook の拒否メッセージ、mise の task description）は日本語で書く
- macOS には GNU `timeout` が無い。timeout が要る script は `timeout` → `gtimeout` → 直接実行の順にフォールバックする
- commit: 小文字の conventional prefix（`fix:` `add:` `feat:` `refactor:`）と短い英語の要約。1 コミットに 1 ツール・1 テーマ（例: `fix: python lsp settings.`）
- PR: 本文は `.github/pull_request_template.md` の節構成に沿って書く。`gh pr create --body` はテンプレートを適用しないので、本文を書く前にテンプレートを読む
- このリポジトリに `CLAUDE.md` / `.claude/CLAUDE.md` / `CLAUDE.local.md` を置かない。どれか 1 つでもあると、Claude Code はこの `AGENTS.md` を読まなくなる
