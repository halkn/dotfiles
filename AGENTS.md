# Repository Guidelines

## Project Structure & Module Organization
このリポジトリは個人用 dotfiles と周辺ツール設定を管理します。主要な設定は `.config/` 配下にあり、`.config/nvim/` は Neovim、`.config/zsh/` はシェル起動、`.config/tmux/` と `.config/zellij/` はターミナル多重化、`.config/ptm/` はツール定義です。AI アシスタント設定は `codex/` と `claude/` にあります。新規ファイルは対象ツールの近くに配置し、既存のディレクトリ命名に合わせてください。

## Build, Test, and Development Commands
- `ln -snf ~/.dotfiles/.config ~/.config`: 管理対象の設定をホーム配下へリンクします。
- `git status --short`: 意図した dotfiles だけが変更されているか確認します。
- `nvim --headless '+quitall'`: Neovim が runtime error なしで起動できるか確認します。
- `zsh -n .config/zsh/.zshenv .config/zsh/conf.d/*.zsh`: `zsh` 設定の構文を確認します。
- `git diff --check`: 余計な空白や patch 形式の崩れを検出します。

## Coding Style & Naming Conventions
変更前に周辺ファイルの書き方を確認し、そのスタイルに合わせてください。Shell は `set -euo pipefail`、小文字の関数名、意味のある環境変数名を基本とします。Lua 設定は `.config/nvim/lua/{core,modules,plugins}/` に役割ごとに分け、プラグイン定義も機能単位で分割します。Markdown は短く実務的に書き、`markdownlint` を前提に整えます。Shell ファイルは `zsh` を含めて `shfmt` で repo の流儀に合わせて整形してください。

## Testing Guidelines
統一的な test harness はないため、変更対象ごとに確認します。
- Shell: `zsh` 変更時は `zsh -n .config/zsh/.zshrc .config/zsh/conf.d/*.zsh` を実行します。
- Neovim: Lua 変更後は `nvim --headless '+quitall'` で起動確認します。
- 文書と整形: `*.md` は `markdownlint`、shell 系ファイルは `shfmt` で確認します。
対話的な変更は PR に手動確認内容を 1 行で添えてください。

## Commit & Pull Request Guidelines
最近の履歴では `fix: python lsp settings.` や `add: codex settings.` のような短い conventional 形式が使われています。`fix:`, `add:`, `feat:` などの小文字 prefix に短い要約を続け、1 つのツールまたは 1 つのテーマに絞ってコミットしてください。PR では変更理由、影響範囲 (`nvim`, `zsh`, `codex` など)、必要なら確認手順を明記します。見た目が変わる場合のみスクリーンショットを付けてください。

## Security & Configuration Tips
シークレット、トークン、端末固有の認証情報はコミットしないでください。symlink や path は可能な限りポータブルに保ち、このリポジトリにローカル専用の状態ファイルを書き込まないでください。
