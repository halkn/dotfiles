---
paths:
  - ".config/nvim/**"
  - "**/*.lua"
---

# Neovim Design Principles

方針: 「標準機能を軸に、足りない部分だけを小さく補う」。検証手順は `/neovim-lua` skill。

**構成:**

- `lua/vimrc/` 配下で役割ごとに分ける。プラグイン定義は 1 ファイルにまとめる
- `lazy load` は採用しない（初期化順序の明快さを優先）
- plugin manager は Neovim 標準のものを使う
- plugin の追加条件: 責務が単一・標準機能では不足が明確・既存の操作感を崩さない。UI 系（`statusline`、`picker`、`notify`）は自作を優先する

**LSP:**

- `g` は移動・ジャンプの prefix。ジャンプ系をここに置き、rename・symbol・code action は `<F2>` と `<LocalLeader>` に置く
- 標準が既定で持つマッピングは張り直さない。特に `gr` を buffer-local に張ると `gr*` 系の入力が全て 'timeoutlen' 待ちになる（`:help map-nowait`）。自前で張るのは標準に無いものだけ
- 標準の既定は、自前のキーと二重になっても消さずに残す。他環境との差分を小さく保つ
- `LspAttach` で張るキーマップは `client:supports_method()` で分岐する。server が持たない機能のキーが残るとエラーになる
- `LspAttach` で作った buffer-local の autocmd は `LspDetach` で外す。augroup はバッファごとに作らず単一 augroup + `buffer` 指定にする
- server 単位で決まる capability の調整は、その server の設定ファイル内で完結させる。`LspAttach` で他 client の有無を見る形は attach 順に依存して落ちる
- `lsp/<name>.lua` は 1 サーバー 1 ファイルで自己完結させる。数行の重複は共通モジュール化しない

**ツールチェーン:**

- formatter と diagnostics は、editor 内で使うものと CI で使うものが同じ結果になる組み合わせを選ぶ
- ツールの宣言先は呼び出し元で決める。nvim が任意のディレクトリで呼ぶものは `.config/mise/config.toml`、このリポジトリの `mise run` だけが使うものは `mise.toml`
- `mise.toml` のツールはこのリポジトリの外で PATH に載らない。PATH を直接参照する server 設定は他リポジトリで attach しない（Lua はここでしか書かないため許容している）

**検査の維持:**

- 静的検査の警告は 0 件を維持する。`---@diagnostic disable` は使わず型注釈で解く
- 診断を無効化してよいのは、その診断がこの構成では常に無意味なときだけ
- 静的検査は `vim.*` の遅延ロードモジュールに届かない。smoke test が持つのは wiring と integration の代表操作で、module 単体の回帰はその module 側に置く
