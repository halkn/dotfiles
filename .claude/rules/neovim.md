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

- formatter: `stylua` が正。editor 内では `emmylua_ls` が external formatter として呼び出す
- diagnostics: `emmylua_check` と editor 内の `emmylua_ls` が正
- nvim 専用ツール（`tree-sitter`）は nvim にバンドルし、グローバル PATH には通さない
- CLI でも使うツール（`emmylua_ls`・`emmylua_check`・`stylua`・`shuck`）はグローバル PATH に置く

**変更時の手順:**

1. `mise run fmt` で整形（`stylua` + `shuck`）
1. `mise run lint` で確認（`stylua --check`・`emmylua_check`・起動確認）
1. tools がない場合は先に `mise run setup` を実行する
1. `.config/nvim/.emmyrc.json` の前提（`statusline`・`vim` global 等）を崩さないこと
