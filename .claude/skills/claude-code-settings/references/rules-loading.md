# 指示のロード条件

`.claude/rules/*.md`・サブディレクトリの `CLAUDE.md`・Read/Edit/Write matcher の hook が、いつ context に載る / 発火するか。判断基準は `.claude/rules/claude-code.md` と `claude/CLAUDE.md`、ここに置くのはその裏取り。

## 実測（v2.1.273 / Linux）

- `paths:` を持たない rule とリポジトリ直下の `CLAUDE.md` は、セッション開始時に全量が載る
- `paths:` を持つ rule とサブディレクトリの `CLAUDE.md` は、**Read tool が一致するファイルを開いた時点**で追加される。Bash（`cat` / `sed`）・Grep・Glob・Edit・Write はいずれも契機にならない
- 一致は Managed / User / Project の 3 スコープで評価される。User（`~/.claude/rules/`）の `paths:` も効くが、glob の基準が cwd なので、リポジトリ名を含まない `paths:` は無関係なリポジトリでも当たる
- 一度載った rule は同一セッションで再度載らない

再現手順:

```sh
mkdir -p repro/.claude/rules repro/src && cd repro
printf -- '---\npaths:\n  - "src/**"\n---\n\nreply with RULE-LOADED-7731\n' > .claude/rules/scoped.md
printf 'hello\n' > src/hello.txt
echo 'Use the Read tool to read src/hello.txt, then reply with every XXX-LOADED-NNNN token in your context, or NO-TOKENS.' | claude -p --allowedTools=Read
echo 'Use the Bash tool to run `cat src/hello.txt`, then reply with every XXX-LOADED-NNNN token in your context, or NO-TOKENS.' | claude -p --allowedTools=Bash
```

Read 側は token を返し、Bash 側は `NO-TOKENS` を返す。`--allowedTools` は可変長引数なので `=` で繋がないとプロンプトを飲み込む。

## Bash 優先の指示

auto / bypassPermissions のセッションに、`cat` / `sed` / heredoc をファイル tool より優先させる system 指示が注入されることがある。上のロード契機が成立しなくなるため、path-scoped rule・nested `CLAUDE.md`・Read/Edit/Write matcher の hook が黙って効かなくなる。

- kill switch は `env` の `CLAUDE_CODE_THRIFTY_SONIC`（unset = モデルごとのロールアウトに従う / `"0"` = 無効 / `"1"` = 有効）。`claude/settings.json` に `"0"` を置いてある
- 未文書化のフラグで、公式 docs・CHANGELOG に記載が無い。出典は anthropics/claude-code#92271（注入文言・値の扱い・影響範囲、closed）と #89731（open）。docs に載るか挙動が変わったら置き直す
- フラグ名は配布物によっては存在しない。remote 実行環境の bundle（2.1.273）には文字列が無く、指示は server 側から注入されていた。`"0"` が効いているかは、auto モードのセッションで実際に Read tool が使われるかで見る
- このリポジトリの hook は 3 本とも matcher が `Bash` なので、この指示下でも発火し続ける
