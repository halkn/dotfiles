# mise の設計

対象は `mise.toml`・`.config/mise/`・`mise-tasks/`。

## 原則

- マシンの状態（symlink の配置・ツール・OS パッケージ・clone するリポジトリ・ログインシェル）は、全て mise の設定（ツールは `.config/mise/config.toml`、それ以外は `mise.toml`）に宣言し、`mise bootstrap` で収束させる。同じ状態を手順書やスクリプトに二重に書かない。インストールの入口も `mise bootstrap` だけにし、task の実行時に自動で入れない
- バージョンを動かす入口は `mise run update` だけにする。`mise run sync` は、pull した宣言に収束させるだけで、バージョンを動かさない
- OS 固有の処理は必要な箇所に閉じ込め、macOS / WSL の分岐を設定全体に持ち込まない

## ツールの宣言先

- mise で入れるツールは、全て `.config/mise/config.toml`（全プロジェクトに効く）に宣言し、版を固定しない。`mise.toml` には `[tools]` を置かず、このリポジトリでしか使わないツール（Lua の `stylua`・`emmylua_ls`・`emmylua_check`）もグローバルに置く
- 固定しないことで起きる次の 2 つは許容する
  - `lint` が使うツールの版がマシン間・CI と手元の間でずれ、`lint` の結果が変わる
  - lockfile の checksum が無いので、既存のリリースの asset が差し替えられると、`minimum_release_age` を通り抜けてそのまま入る
- ツールは、できるだけ他の依存が無い形で入れる。node や python に依存する配布（npm・pipx）は避ける。その上で registry の短縮名を優先し、registry に無いものや依存が増えるものだけ backend を明示する
- LSP・formatter・linter は、その言語の toolchain と同じ場所に置く。Go はグローバルなので `gopls` も `.config/mise/config.toml` に、Python はプロジェクトの環境で固定するので `pyright`・`ruff` は mise で宣言せずそのプロジェクトの環境から起動する。TypeScript も同様に、`tsc`・`oxlint`・`oxfmt` はプロジェクトの `node_modules` から起動する
- JavaScript の runtime は bun だけを入れ、node は入れない。npm の配布物は node の shebang を持つので、bun に `--bun` で実行させる。プロジェクトに無いツールを勝手に取得しないよう、`bunx` には `--no-install` を付ける
- shell の alias・関数は zsh に置く。追跡する mise 設定の `[env]` は、プロジェクト固有の環境変数だけに使う。マシン固有の値は追跡外の `*.local` に置く
- 新しい CLI が設定ディレクトリや認証情報を読む場合は、Claude Code の sandbox 側の設定も要る（[claude-code.md](claude-code.md)）

## task

- 1 行のコマンドを並べるだけの task は `mise.toml` に書く。分岐・ループ・変数が要るロジックは `mise-tasks/` のファイル task にし、`shuck` の検査対象にする。ファイル task には実行ビットを付ける
- 検査やテストを行う task を足したら、`lint` の `depends` に加える。`lint` が全ての検査の入口になる
- 単独で走らせる意味がある task（時間のかかる検査・テスト）だけを表示し、`lint` の一部としてしか使わないものは `hide = true` にする
