# 設計ドキュメント

このリポジトリを変更する人と agent のための設計方針。変更する前に、触る対象の doc を読む。

| 触る対象 | doc |
| --- | --- |
| `mise.toml`・`mise-tasks/`・`.config/mise/`、ツールの追加 | [mise.md](mise.md) |
| `.zshenv`・`.config/zsh/`・`bin/`・`.config/herdr/`・`test/` | [shell.md](shell.md) |
| `.config/nvim/` | [neovim.md](neovim.md) |
| `claude/`・`.claude/` | [claude-code.md](claude-code.md) |
| 上記以外（`.config/git/`・その他の `.config/*`・`.github/`） | 専用の doc は無い。ファイルにコメントがあればそれに従う。git の `pre-push` hook は [claude-code.md](claude-code.md) の push の保護も読む |

## 何をどこに書くか

| 書く内容 | 置き場所 |
| --- | --- |
| セットアップと日常の操作 | リポジトリ直下の `README.md` |
| agent 向けの検証手順と規約 | `AGENTS.md` |
| 複数のファイルにまたがる方針・判断基準、コメントを書けないファイル（JSON）の設定理由 | `docs/` |
| 1 つのファイルで完結する理由・制約 | そのファイルの冒頭コメント |
| コマンドの使い方 | `--help` |

ツールの公式ドキュメントに書いてあることと、コードを読めば分かることは書かない。変更の経緯は commit と PR に残す。

`README.md` は英語、`AGENTS.md` と `docs/` は日本語、コードコメントは英語で書く。
