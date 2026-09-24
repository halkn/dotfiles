# mise の設計

対象は `mise.toml`・`mise.lock`・`.config/mise/`・`mise-tasks/`。

## 原則

- マシンの状態（symlink の配置・ツール・OS パッケージ・clone するリポジトリ・ログインシェル）は、全て `mise.toml` に宣言し、`mise bootstrap` で収束させる。同じ状態を手順書やスクリプトに二重に書かない。インストールの入口も `mise bootstrap` だけにし、task の実行時に自動で入れない
- バージョンを動かす入口は `mise run update` だけにする。`mise run sync` は、pull した宣言に収束させるだけで、バージョンを動かさない
- OS 固有の処理は必要な箇所に閉じ込め、macOS / WSL の分岐を設定全体に持ち込まない

## ツールの宣言先

| 宣言先 | 置くもの | バージョン |
| --- | --- | --- |
| `.config/mise/config.toml`（全プロジェクトに効く） | どのディレクトリからでも呼ばれる CLI（shell から使うもの、Neovim が起動する formatter・LSP、全リポジトリで使う検査） | 固定しない |
| `mise.toml` | このリポジトリの中でだけ使うもの（Lua toolchain） | `mise.lock` で固定する |

- 宣言先は、どこから呼ばれるかより、対象のファイルがどこにあるかで決める。Lua はこのリポジトリでしか書かないので、Neovim から起動する `emmylua_ls` も `mise.toml` に置く
- 固定するかどうかは宣言先の結果で、固定したいからといってグローバルのツールを `mise.toml` に移さない。`lint` が使うグローバルのツール（`rumdl`・`shuck`・`nvim`）の版がマシン間でずれ、`lint` の結果が変わることは許容する
- ツールは、できるだけ他の依存が無い形で入れる。node や python に依存する配布（npm・pipx）は避ける。その上で registry の短縮名を優先し、registry に無いものや依存が増えるものだけ backend を明示する
- LSP・formatter・linter は、その言語の toolchain と同じ場所に置く。Go はグローバルなので `gopls` も `.config/mise/config.toml` に、Python はプロジェクトの環境で固定するので `pyright`・`ruff` は mise で宣言せずそのプロジェクトの環境から起動する
- shell の alias・関数は zsh に置く。追跡する mise 設定の `[env]` は、プロジェクト固有の環境変数だけに使う。マシン固有の値は追跡外の `*.local` に置く
- 新しい CLI が設定ディレクトリや認証情報を読む場合は、Claude Code の sandbox 側の設定も要る（[claude-code.md](claude-code.md)）

## task

- 1 行のコマンドを並べるだけの task は `mise.toml` に書く。分岐・ループ・変数が要るロジックは `mise-tasks/` のファイル task にし、`shuck` の検査対象にする。ファイル task には実行ビットを付ける
- 検査やテストを行う task を足したら、`lint` の `depends` に加える。`lint` が全ての検査の入口になる
- 単独で走らせる意味がある task（時間のかかる検査・テスト）だけを表示し、`lint` の一部としてしか使わないものは `hide = true` にする
