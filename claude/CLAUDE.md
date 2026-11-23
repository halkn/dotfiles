# Global Instructions

@preferences.md

## ローカル環境

ここから下は、このリポジトリの `settings.json`（sandbox・`blockReadsOutsideWorkingDirectories`）で動くローカルの Claude Code に向けた規則。

### 仕様の確認

- `allowedDomains` にある docs は `curl` で取得して `rg` で原文を確かめる。それ以外は WebFetch（tool が無いセッションでは `web-fetch` agent）
  - Bash に `allowed_domains` を付けない（`strictAllowlist` で拒否される）。allowlist に無いホストへの通信が要るコマンドは、`!` での実行を頼む

### 環境

- 検索は `rg`、構文を条件にする検索・変換は `ast-grep`。値の確認は `jq` / `yq`、YAML 構文は `ryl`
  - 呼出しの引数・形を複数箇所で変える書き換えは、Edit の繰り返しや `sed` ではなく `ast-grep run -p '<pattern>' -r '<rewrite>' -l <lang>` で行う。`-U` の前に一度 `-U` 無しで一致を確かめる。テキスト置換は改行や入れ子の呼出しで漏れる
- Bash は作業ディレクトリの中で動かす。作業ディレクトリの外のパスを書いた Bash と、sandbox の外で動くコマンドの追えない展開は、auto モードでも `blockReadsOutsideWorkingDirectories` の確認になる
  - ファイルの書き換えは Edit / Write tool で行う。ハーネスは auto モードで Bash での書き換えを勧めるが、それが確認の主な原因になっている
  - 一時ファイルはハーネスの指示どおり scratchpad に置き、Read / Write / Edit tool で扱う
  - `~/.claude` の skills・plugins・agents・commands・rules は Read tool で読む。Bash で読むと確認になる
  - 他のリポジトリでは `~/.claude/CLAUDE.md`・`settings.json` を Read でも読めない。CLAUDE.md は会話に読み込まれた本文を使い、settings.json が要るなら halkn/dotfiles のセッションに引き継ぐ
  - 上流のソースは `gh api -H 'Accept: application/vnd.github.raw' 'repos/<o>/<r>/contents/<path>?ref=<版>'` で読み、`--jq` は付けない（応答が JSON でない）
  - 手元にある他のリポジトリの clone（`~/repos` の下）は、読む前に `/add-dir` を頼む。`~/.local/share` のインストール先は Bash で読み、確認を受け入れる
- sandbox・`blockReadsOutsideWorkingDirectories` の拒否と依存の取得（`mise install` など）は、`/add-dir` か `!` での実行をユーザーに頼む。ただし PATH に載るバイナリやプラグインを置く data ディレクトリ（`~/.local/share` など）は `/add-dir` に出さない（sandbox の書込まで開く）。hook・`pre-push` の拒否は、メッセージに従って自分で直す

### Git

- `gh` の全サブコマンド（読取を含む）と git の push・fetch・clone・ls-remote は、他のコマンドとパイプ・`;`・`&&`・ループで繋がず単体で打ち、出力は `--jq` で絞る。`git pull` は `git fetch` と `git merge` に分ける
  - `gh` は sandbox の外で動き、追えない引数は確認になる。`--jq` は `.[] | "\(.a)\t\(.b)"` のような文字列補間の形にし、配列の構築（`[.a, .b] | @tsv`・`[.a] | join(…)`）・スライス（`.sha[0:7]`）・`select(.a=="b")` を入れない
