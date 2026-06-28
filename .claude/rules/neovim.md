---
paths:
  - ".config/nvim/**"
  - "**/*.lua"
---

# Neovim Design Principles

方針: 「標準機能を軸に、足りない部分だけを小さく補う」

**Plugin 制約:**

- `lazy load` は採用しない（初期化順序の明快さを優先）
- 追加条件: 責務が単一・標準機能では不足が明確・既存の操作感を崩さない
- plugin manager は Neovim 標準パッケージマネージャーを使用する
- UI 系（`statusline`、`picker`、`notify`）は自作を優先する

**ツールチェーン:**

- formatter: `stylua` が正。`luals` の built-in formatter を主担当に戻さないこと
- diagnostics: `lua-language-server --check` と editor 内の `luals` が正
- nvim 専用ツール（`efm-langserver`・`tree-sitter`）は nvim にバンドルし、グローバル PATH には通さない
- CLI でも使うツール（`lua-language-server`・`stylua`・`shfmt`）はグローバル PATH に置く

**変更時の手順:**

1. `just fmt` で整形（`stylua` + `shfmt`）
2. `just lint` で確認（`stylua --check`・`lua-language-server --check`・起動確認）
3. tools がない場合は先に `just setup` を実行する
4. `.config/nvim/.luarc.json` の前提（`statusline`・`vim` global 等）を崩さないこと
