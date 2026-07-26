# Azure Repos（`az repos`）

`origin` が `dev.azure.com` / `ssh.dev.azure.com` / `*.visualstudio.com` の場合に読む。共通のフロー・コミット規約は `SKILL.md` を参照。

`az repos` は azure-devops 拡張のコマンドで、初回実行時に自動インストールされる。

## organization / project の解決

`az repos pr create` は organization と project を必要とするが、以下の順で解決される。

1. `--organization` / `--project` の明示指定
1. `az devops configure --defaults` で設定された既定値
1. git remote からの自動検出

まず `az devops configure --list` で既定値を確認する。既定値が設定済みなら `--organization` / `--project` は省略してよい。未設定なら、勝手に `az devops configure` で既定値を書き込まない — ユーザーのグローバル設定を変えることになるので、その場では `--organization` / `--project` を明示指定して済ませる。

organization と project は origin URL から読める。

```text
https://dev.azure.com/{organization}/{project}/_git/{repository}
git@ssh.dev.azure.com:v3/{organization}/{project}/{repository}
https://{organization}.visualstudio.com/{project}/_git/{repository}
```

## PR テンプレート

PR を作る前に、リポジトリにテンプレートがあるか確認する。

```bash
git ls-tree -r --name-only origin/HEAD | grep -i pull_request_template
```

**テンプレートは既定ブランチ（通常 `main`）のものだけが使われる**仕様なので、作業ブランチではなく既定ブランチの tree を見る。作業ブランチで追加・編集したテンプレートは、マージされるまで効かない。

`origin/HEAD` は clone の仕方によっては設定されておらず、その場合このコマンドは失敗する。`git remote set-head origin --auto` で設定するか、既定ブランチ名を直接指定する（`git ls-tree -r --name-only origin/main | ...`）。

Azure Repos が認識する場所は、リポジトリルート・`.azuredevops/`・`.vsts/`・`docs/` のいずれかに置かれた `pull_request_template.md`（`.txt` も可）。この順に検索され、最初に見つかったものが既定テンプレートになる。

テンプレートには 3 種類ある。

- **既定** — 上記の `pull_request_template.md`。すべての PR に適用される
- **ブランチ別** — `<上記フォルダ>/pull_request_template/branches/<ブランチ名>.md`。target branch がそのブランチ（または配下）のとき、既定より優先される。`dev.md` は `dev` と `dev/*` に効く
- **追加** — `<上記フォルダ>/pull_request_template/` 直下の任意のファイル。作成者が任意で追記するもの

target branch が既定ブランチ以外なら、まず `pull_request_template/branches/` に該当するものが無いか見る。

**`--description` を渡すと description はその内容そのものになる。** テンプレートの自動適用は Web UI 上の挙動なので、CLI 経由では当てにしない。テンプレートを読んで埋めた本文を、1 行 1 値に分けて `--description` に渡す。

## PR 作成

```bash
az repos pr create \
  --repository <repo> \
  --source-branch <branch> \
  --title "<title>" \
  --description "1 行目" "2 行目" "3 行目" \
  --work-items 123 456
```

GitHub との差分で間違えやすい点:

- **`--repository` は実質必須**。`gh` のように作業ディレクトリから完全に推測してはくれない
- **`--source-branch` を明示する**。現在のブランチが自動採用されるとは限らない
- **`--description` は 1 値 = 1 行**。`--description "First" "Second"` で 2 行になる。`gh` の `--body-file` に相当する引数は無いので、本文を 1 行ずつ分解して複数値として渡す。Markdown は使える。空行の扱いは下記「本文の組み立て」を参照
- `--target-branch` は省略するとリポジトリの既定ブランチ。既定ブランチ以外へ向けるときだけ明示する
- 途中段階なら `--draft true`（`gh` と違いフラグではなく真偽値を取る）
- ブラウザを開く `--open` は使わない（ヘッドレス環境で止まる）

作成後は PR ID と URL を報告する。

## 本文の組み立て

1 値 = 1 行なので、**Markdown の空行も 1 つの値として渡す**必要がある。見出しの直後に空行が無いと、後続の段落やリストが見出しと同じ行として扱われて崩れる。空行は空文字列 `""` を値として挟む。

```bash
az repos pr create --repository <repo> --source-branch <branch> \
  --title "fix: null check in order parser" \
  --description \
    "## 変更理由" \
    "" \
    "注文パーサが null を踏んで落ちていた。" \
    "" \
    "## 確認手順" \
    "" \
    "- \`pytest tests/parser\` — 全件 pass"
```

PR テンプレートを埋めて渡す場合、テンプレートには必ず空行が含まれるため、この分解を省くと本文が崩れる。

**作成後に `az repos pr show --id <PR ID>` で本文を確認する。** 空文字列の扱いは az CLI のバージョンによって差がありうるので、崩れていたら `az repos pr update --id <PR ID> --description ...` で直す。1 回確認すればその環境での挙動が分かる。

## work item の紐付け

Azure Boards の work item は、GitHub の issue と違って PR 本文のキーワードでは紐付かない。**`--work-items <ID> <ID>` で明示的に渡す**のが確実。

commit メッセージ側では、`#123` と書くと push 時に work item 123 への Commit リンクが作られる。GitHub 感覚で issue 番号のつもりの `#` を書くと、無関係な work item に誤ってリンクされる。work item ID を意図しない限り commit メッセージに `#` + 数字を書かない。

```text
fix: null check in order parser. #123
```

`AB#123` 記法は **GitHub リポジトリから Azure Boards を参照する**ときのものであり、Azure Repos 上では使わない。

work item ID がユーザーから示されていない場合は、推測でリンクしない。紐付けるべき work item があるか確認する。

## 既存 PR の操作

- 一覧: `az repos pr list --repository <repo> --status active`
- 詳細: `az repos pr show --id <PR ID>`
- 更新: `az repos pr update --id <PR ID> --title ... --description ...`
- work item 追加: `az repos pr work-item add --id <PR ID> --work-items <ID>`

## 使わないもの

- `--auto-complete` / `--bypass-policy` / `--squash` / `--delete-source-branch` はマージ挙動やブランチポリシーを変える。ユーザーが明示的に指示した場合だけ使う
- `az devops invoke` の書き込み系（POST / PATCH / PUT / DELETE）は `claude/settings.json` の `permissions.deny` で禁止されている。専用の `az repos` サブコマンドで代替する
