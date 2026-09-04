---
description: このリポジトリの zsh 設定（.config/zsh 配下の .zshenv・.zshrc・workflows/・lib/・test/、.config/herdr/*.sh）を変更するときの検証手順と実測記録。workflow に関数を足す、picker の挙動を変える、test/ に検査を足す、herdr から呼ばれる関数を直す、といった作業で使う。
---

# zsh workflow の検証

判断基準そのものは `.claude/rules/zsh.md`。ここに置くのは、その基準を満たすための手順と、確認済みの実測記録。

## 手順

1. `mise run fmt` で整形する（`shuck format .`）
1. `mise run lint` で確認する（`shuck` の検査と `test/` の実行を含む）
1. zsh だけを回すときは `mise run test:zsh`
1. ツールが無い場合は先に `mise install`

`shuck` はリポジトリ全体（`.`）が対象。シェルスクリプトを足しても `mise.toml` への登録は要らない。

## test/ に検査を足す

`.config/zsh/test/` は 1 ファイル 1 対象で、何を見るかはファイル冒頭のコメントにある。

- lib の関数は入力を引数で渡して出力を照合する。`$WT_ROOT` / `$REPO_ROOT` はテスト内で差し替える
- workflow の関数は依存する lib 関数をテスト内で再定義して切り離す（`_sess_workspace_rows` を差し替える形が既にある）
- picker を開く関数そのものは検査できない。行データを作る関数を切り出して、そちらを検査対象にする

## 検査の届かない範囲

lint も test も次を見ないので、実端末で新規シェルを開いて確認する。

- fzf の widget・completion（`Ctrl-R` / `Ctrl-T` / `Alt-C` / `<command> **<TAB>`）
- herdr の picker と自動起動、`.config/herdr/*.sh` から source される経路
- `.zshenv.local` / `.zshrc.local` は追跡外で lint 対象外

## 実測記録

- `herdr workspace list`（0.8.2）は workspace id・番号・ラベル・checkout path を返すが **branch は返さない**。一覧の行名はこれではなく `_ck_describe` で path から作る
- zsh の `path` は PATH の配列。関数内で `local path` を宣言すると PATH が消える（`wt_path` のような別名を使う）
- zsh 固有構文には `ast-grep` の parser を確認できていない。検索・変換は `rg` と `shuck` に寄せる
