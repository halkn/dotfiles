# mise の設計

## mise を single source of truth にする

symlink の配置・ツール・OS パッケージ・ログインシェルは、全て `mise.toml` に宣言し、`mise bootstrap` で収束させる。同じ状態を手順書やスクリプトに二重に書かない。

## ツールの宣言先

| 宣言先 | 置くもの | バージョン |
| --- | --- | --- |
| `.config/mise/config.toml` | どのディレクトリからでも呼ばれる CLI（shell から使うもの、Neovim が起動する formatter・LSP、全リポジトリで使う検査） | 固定しない。各マシンが導入時に最新を解決する |
| `mise.toml` | このリポジトリの中でだけ使うもの（Lua toolchain。Neovim の `emmylua_ls` もここ） | `mise.lock` で固定する。診断がリリースごとに変わり、lint の結果がマシン間でずれるため |

- `.config/mise/config.toml` は `~/.config/mise/config.toml` として読まれる。変更はこのリポジトリの外の全プロジェクトに効く
- プロジェクトごとに入れる LSP（`pyright`・`ruff` など）は mise で宣言せず、そのプロジェクトの環境から起動する
- `rumdl`・`shuck`・`nvim` はグローバルのツールなので、`lint` の結果がマシン間でずれることがある。揃えるには両方のマシンで `mise run update` を実行する
- shell の alias・関数は zsh に置く。追跡する mise 設定の `[env]` は、プロジェクト固有の環境変数だけに使う。マシン固有の値は追跡外の `*.local` に置く
- 新しい CLI が設定ディレクトリや認証情報を読む場合は、Claude Code の sandbox 側の設定も要る（[claude-code.md](claude-code.md)）

## task

- 1 行のコマンドを並べるだけの task は `mise.toml` に書く。分岐・ループ・変数が要るロジックは `mise-tasks/` のファイル task にし、`shuck` の検査対象にする。書式は既存のファイル task に合わせ、実行ビットを付ける（無いと task がエラーなく消える）
- 検査やテストを行う task を足したら、`lint` の `depends` に加える。`lint` が全ての検査の入口になる

## OS の差

OS 固有の処理は必要な箇所に閉じ込め、macOS / WSL の分岐を設定全体に持ち込まない。
