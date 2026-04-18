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

## Neovim Design Principles
Neovim 設定は「標準機能を軸に、足りない部分だけを小さく補う」方針で保ちます。初期化順序は `core`、`modules`、`plugins` を基本とし、`core` には常時必要な基本設定、`modules` には自作の UI や操作改善、`plugins` には外部依存の薄い機能別プラグインを置いてください。定番プラグインで置き換える前に、Neovim 組み込み API や既存 module で十分かを先に検討します。

plugin は必要最小限に保ち、機能追加のために安易に数を増やさないでください。追加する場合は、責務が単一であること、標準機能では不足が明確であること、既存の操作感を崩さないことを条件にします。`lazy load` は原則として採用せず、起動時間の最適化よりも構成の単純さと初期化順序の明快さを優先してください。

plugin manager は Neovim 標準を優先し、標準パッケージマネージャーで十分な機能がある限り外部 manager は増やしません。将来 Neovim 標準で置き換え可能な機能が入った場合は、既存 plugin の置き換えを検討してください。UI 系は `statusline`、`picker`、`notify` のように自作を優先し、LSP や formatter は言語別設定を分離して管理します。責務の重複は避け、特に format、lint、diagnostics、keymap はどの層が担当するかを明確にしてください。

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
