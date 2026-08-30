# Repository Guidelines

個人用 dotfiles。symlink 配置・mise ツール・OS パッケージ・ログインシェルは全て `mise.toml` の宣言を single source of truth として `mise bootstrap` が適用する。セットアップの全体像は `README.md` を参照。

## Non-obvious layout

- `claude/` が Claude Code 設定の実体。`~/.claude/` は Claude Code 自身が状態を書くのでディレクトリ単位では symlink できず、`mise.toml` の `[dotfiles]` が `claude/*` を 1 エントリずつ張る。glob は毎回展開されるので新規ファイル・サブディレクトリの追加に宣言の変更は要らない。`.claude/` はこのリポジトリ自身のプロジェクト設定で別物
- `.config/mise/config.toml` は `~/.config/mise/config.toml` としても読まれる。ここへの変更はリポジトリ外の全プロジェクトに影響する
- `.config/zsh/` は `.zshenv` / `.zshrc`（portable な shell core）、`workflows/`（ユーザーが打つコマンド）、`lib/`（扱う情報ごとの層）の 3 層に、`test/` が付く。置き場所の基準と制約は `.claude/rules/zsh.md`
- `.claude/skills/` と `.claude/rules/` はこのリポジトリ自身の設定で symlink されない。新規ファイルはそのまま次のセッションで読まれる
- `mise` タスクは 2 箇所に分かれる。1 コマンドで終わるものは `mise.toml`、複数行のロジックは `mise-tasks/` 配下のファイルタスク（サブディレクトリが `lint:` などの名前空間になる。実行ビットが必要で、落ちるとエラーなくタスクが消える）
- `.claude/rules/` の path-scoped ルールを `~/.claude/rules/` へ移さない。`paths:`/`globs:` 指定が user-level では読み込まれない（anthropics/claude-code#19377, #21858）。全プロジェクト共通のルールは `claude/CLAUDE.md` に直接書く

## Verification

- 変更後は `mise run fmt` → `mise run lint`。`lint` は整形チェック・各言語の検査・テストを全て含む（内訳は `mise.toml` の `depends`）
- zsh の関数を足す・振る舞いを変えたら `.config/zsh/test/` に検査を足す（`mise run test:zsh` で単体実行）。各テストが何を対象に何を見るかはファイル冒頭のコメントにある
- 既存警告が多い場合は対象ファイルに絞る（`rumdl check <file>`、`shuck format --check <file>`）
- ツールが無い場合は先に `mise install`（lockfile 固定のまま導入される）
- `shuck` は lint・整形ともリポジトリ全体（`.`）が対象。シェルスクリプトを足すと登録なしで検査対象になるため、追加時に `mise.toml` は変更しない
- 更新系（`mise run setup` / `sync` / `update`）はユーザーが手動実行する
- `mise bootstrap --force-dotfiles` は競合ファイルをバックアップなしで上書きする。提案する前に `mise bootstrap --dry-run` で差分を示す
- 対話操作でしか確認できない変更は、PR に手動確認の内容を 1 行添える

## Conventions

- macOS に GNU `timeout` は無い。timeout が要る script は `timeout` / `gtimeout` / 直接実行の順にフォールバックする
- 整形は `mise run fmt` に任せる（`shuck`・`stylua`・`rumdl`）
- コードコメントは英語で書く。識別子・コマンド名と同じ語彙で書けるため。ユーザーに表示される文字列（hook の拒否メッセージ、`mise` の task description）は日本語のまま
- 情報の置き場所は「いつ読む必要があるか」で決める。判断基準は `.claude/rules/*.md`（path 一致で常時ロード・各 40 行以内、`mise run lint` が検査する）、手順と実測記録は `.claude/skills/*/`（呼ばれたときだけロード）、変更の経緯は commit と PR。コード側には、その実装でなければならない理由と、どちらにも無い実装固有の制約だけを残す
- commit: 小文字 conventional prefix（`fix:` `add:` `feat:` `refactor:`）+ 短い英語要約。1 コミット 1 ツール・1 テーマ（例: `fix: python lsp settings.`）
- PR: 本文は `.github/pull_request_template.md` の節構成に沿う。`gh pr create --body` はテンプレートを適用しないので、本文を書く前にテンプレートを読む

## Machine-local overrides（gitignore 対象）

端末固有の設定は追跡外の `*.local` ファイルに置く: `.config/zsh/.zshenv.local`（環境変数）、`.config/zsh/.zshrc.local`（インタラクティブ）、`.config/mise/config.local.toml`（global mise の `[env]` / tool / setting override）、`mise.local.toml`（このリポジトリの mise override）、`.config/git/config.local`（`user.name` / `user.email`）。
