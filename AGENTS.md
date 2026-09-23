# Repository Guidelines

個人用 dotfiles。symlink 配置・mise ツール・OS パッケージ・ログインシェルは全て `mise.toml` の宣言を single source of truth として `mise bootstrap` が適用する。セットアップの全体像は `README.md` を参照。

## Non-obvious layout

- `claude/` が Claude Code 設定の実体。`~/.claude/` は Claude Code 自身が状態を書くのでディレクトリ単位では symlink できず、`mise.toml` の `[dotfiles]` が `claude/*` を 1 エントリずつ張る。glob は毎回展開されるので新規ファイル・サブディレクトリの追加に宣言の変更は要らない。`.claude/` はこのリポジトリ自身のプロジェクト設定で別物
- `.config/mise/config.toml` は `~/.config/mise/config.toml` としても読まれる。ここへの変更はリポジトリ外の全プロジェクトに影響する
- `.config/zsh/` は `.zshrc` / `workflows/` の層に分かれる。`bin/` と `.config/herdr/` のテストはリンクされない直下の `test/` に置く。置き場所の基準と検証手順は `.claude/skills/zsh-workflows/SKILL.md`
- `bin/` は shell 関数にしないコマンドの置き場で、`[dotfiles]` が `~/.local/bin/*` へ 1 エントリずつ張る（`$XDG_BIN_HOME` は `.config/zsh/.zshenv` で PATH 上）。`bin/repo`・`bin/wt` は将来この repo の外へ出す前提なので `.config/zsh/` や `.config/herdr/` の zsh ファイルを source しない。共有するのは `$REPO_ROOT`・`$WT_ROOT` とその下のレイアウトだけ
- `.claude/skills/` はこのリポジトリ自身の設定で symlink されない。新規ファイルはそのまま次のセッションで読まれる
- エージェント向けの指示はこのファイルに書く。Claude Code が `AGENTS.md` を直接読むのは working directory とその上位に `CLAUDE.md` / `.claude/CLAUDE.md` / `CLAUDE.local.md` が無いときだけなので、このリポジトリにそれらを置かない（`~/.claude/CLAUDE.md` は対象外で併読される。Claude Code 2.1.278 で確認）
- `mise` タスクは 2 箇所に分かれる。1 コマンドで終わるものは `mise.toml`、複数行のロジックは `mise-tasks/` 配下のファイルタスク（サブディレクトリが `lint:` などの名前空間になる。実行ビットが必要で、落ちるとエラーなくタスクが消える）

## Verification

- 変更後は `mise run fmt` → `mise run lint`。`lint` は整形チェック・各言語の検査・テストを全て含む（内訳は `mise.toml` の `depends`）
- zsh の関数を足す・振る舞いを変えたら `test/` に検査を足す
- 既存警告が多い場合は対象ファイルに絞る（`rumdl check <file>`、`shuck format --check <file>`）
- ツールが無い場合は先に `mise install`（`mise.lock` にあるものは固定のまま、グローバルツールは解決して導入される）
- `shuck` は lint・整形ともリポジトリ全体（`.`）が対象。シェルスクリプトを足すと登録なしで検査対象になるため、追加時に `mise.toml` は変更しない
- 更新系（`mise run sync` / `update`）と `mise bootstrap` はユーザーが手動実行する
- `mise bootstrap --force-dotfiles` は競合ファイルをバックアップなしで上書きする。提案する前に `mise bootstrap --dry-run` で差分を示す
- 対話操作でしか確認できない変更は、PR に手動確認の内容を 1 行添える

## Conventions

- macOS に GNU `timeout` は無い。timeout が要る script は `timeout` / `gtimeout` / 直接実行の順にフォールバックする
- 整形は `mise run fmt` に任せる（`shuck`・`stylua`・`rumdl`）
- コードコメントは英語で書く。識別子・コマンド名と同じ語彙で書けるため。ユーザーに表示される文字列（hook の拒否メッセージ、`mise` の task description）は日本語のまま
- 判断基準・手順・実測記録は skill が持つ。対象を触る前に、その skill を読む。長さは `mise run lint`（`lint:skills`）が検査し、`SKILL.md` 100 行・`references/*.md` 80 行を超えると落ちる
  - `.config/nvim/**`・`**/*.lua` → `.claude/skills/neovim-lua/SKILL.md`
  - `.config/zsh/**`・`.config/herdr/**`・`bin/**`・`test/**`・`**/*.zsh`・`.zshenv` → `.claude/skills/zsh-workflows/SKILL.md`
  - `claude/**`・`.claude/**` → `.claude/skills/claude-code-settings/SKILL.md`
- 変更の経緯は commit と PR が持つ。skill にも AGENTS.md にも書かない。コード側には、その実装でなければならない理由と、どちらにも無い実装固有の制約だけを残す
- commit: 小文字 conventional prefix（`fix:` `add:` `feat:` `refactor:`）+ 短い英語要約。1 コミット 1 ツール・1 テーマ（例: `fix: python lsp settings.`）
- PR: 本文は `.github/pull_request_template.md` の節構成に沿う。`gh pr create --body` はテンプレートを適用しないので、本文を書く前にテンプレートを読む
- 端末固有の設定は追跡外の `*.local` ファイルに置く（一覧は `README.md` の Machine-local settings）。共有したい設定をそこに書かない
