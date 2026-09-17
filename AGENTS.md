# Repository Guidelines

個人用 dotfiles（macOS / WSL Ubuntu）。zsh・Neovim・Claude Code と周辺 CLI の設定を持つ。symlink 配置・mise ツール・OS パッケージ・ログインシェルは `mise.toml` の宣言が single source of truth で、`mise bootstrap` が適用する。人間向けのセットアップ手順は `README.md`。

## Source of truth

現在の値・現在の仕様は次の場所に聞く。Markdown へ複製しない。

- machine state（symlink・ツール・OS パッケージ・ログインシェル）: `mise.toml` と `.config/mise/config.toml`。版は `mise.lock` と `.config/mise/mise.lock`
- コマンドの使い方: `wk --help`・`ghsetup --help`・`mise tasks`。Neovim は user command の `desc` と `:help`
- 外部ツールの仕様: 公式 docs と `--help`。リポジトリ内の記述を根拠にしない
- 過去の経緯: commit と PR

## Non-obvious layout

- `claude/` が Claude Code 設定の実体。`~/.claude/` は Claude Code 自身が状態を書くのでディレクトリ単位では symlink できず、`mise.toml` の `[dotfiles]` が `claude/*` を 1 エントリずつ張る。glob は毎回展開されるので新規ファイル・サブディレクトリの追加に宣言の変更は要らない。`.claude/` はこのリポジトリ自身のプロジェクト設定で別物
- `~/.config` はこのリポジトリへの symlink。パスを解決する仕組み（sandbox の allow / deny など）は実体パスで書かないと効かない
- `.config/mise/config.toml` は `~/.config/mise/config.toml` としても読まれる。ここへの変更はリポジトリ外の全プロジェクトに影響する
- `.config/zsh/` は `.zshrc` / `workflows/` / `lib/` / `test/` の層に分かれる
- `mise` タスクは 2 箇所に分かれる。1 コマンドで終わるものは `mise.toml`、複数行のロジックは `mise-tasks/` 配下のファイルタスク（サブディレクトリが `lint:` などの名前空間になる。実行ビットが必要で、落ちるとエラーなくタスクが消える）
- 端末固有の設定は追跡外の `*.local` ファイルに置く（一覧は `README.md`）。共有したい設定をそこに書かない

## Verification

- 変更後は `mise run fmt` → `mise run lint`。`lint` は整形チェック・各言語の検査・テストを全て含む（内訳は `mise.toml` の `depends`）
- zsh の関数を足す・振る舞いを変えたら `.config/zsh/test/` に検査を足す
- 既存警告が多い場合は対象ファイルに絞る（`rumdl check <file>`、`shuck format --check <file>`）
- ツールが無い場合は先に `mise install`（lockfile 固定のまま導入される）
- `shuck` は lint・整形ともリポジトリ全体が対象。シェルスクリプトを足すと登録なしで検査対象になる
- lockfile の diff は理由を問わず commit する（`mise.lock`・`.config/mise/mise.lock`・`.config/nvim/nvim-pack-lock.json`）。手で編集しない
- 対話操作でしか確認できない変更は、PR に手動確認の内容を 1 行添える

## 実行しない操作

- 更新系（`mise run setup` / `sync` / `update`）はユーザーが手動で実行する
- `mise bootstrap --force-dotfiles` は競合ファイルをバックアップなしで上書きする。提案する前に `mise bootstrap --dry-run` で差分を示す

## Conventions

- 依頼の範囲外の整形・リファクタリングを混ぜない
- 整形は `mise run fmt` に任せる（`shuck`・`stylua`・`rumdl`）
- macOS に GNU `timeout` は無い。timeout が要る script は `timeout` / `gtimeout` / 直接実行の順にフォールバックする
- コードコメントは英語で書く。識別子・コマンド名と同じ語彙で書けるため。ユーザーに表示される文字列（hook の拒否メッセージ、`mise` の task description）は日本語のまま
- commit: 小文字 conventional prefix（`fix:` `add:` `feat:` `refactor:`）+ 短い英語要約。1 コミット 1 ツール・1 テーマ
- PR: 本文は `.github/pull_request_template.md` の節構成に沿う。テンプレートを適用しないクライアントがあるので、本文を書く前にテンプレートを読む

## Scoped guidance

領域ごとの設計原則は `.claude/rules/`、作業手順と検証方法は `.claude/skills/`。その領域を変更する前に該当ファイルを読む。

| 変更対象 | 設計原則 | 手順 |
| --- | --- | --- |
| `.config/zsh/**`・`.config/herdr/**` | `.claude/rules/zsh.md` | `.claude/skills/zsh-workflows/` |
| `.config/nvim/**` | `.claude/rules/neovim.md` | `.claude/skills/neovim-lua/` |
| `claude/**`・`.claude/**` | `.claude/rules/claude-code.md` | `.claude/skills/claude-code-settings/` |
