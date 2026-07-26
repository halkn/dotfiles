# GitHub（`gh`）

`origin` が `github.com` の場合に読む。共通のフロー・コミット規約は `SKILL.md` を参照。

## PR テンプレート

PR を作る前に、リポジトリにテンプレートがあるか確認する。

```bash
git ls-files | grep -i pull_request_template
```

GitHub が認識する場所は、リポジトリルート・`.github/`・`docs/` に置かれた `pull_request_template.md`（大文字小文字は区別されない）。複数テンプレートを持つリポジトリでは `.github/PULL_REQUEST_TEMPLATE/` 配下に複数ファイルが並ぶ。その場合は変更内容に最も合うものを選び、判断が付かなければユーザーに聞く。

テンプレートは既定ブランチのものが使われる。作業ブランチでテンプレート自体を追加・変更している場合、作業ツリーの内容と実際に適用されるものが食い違うので、`git ls-tree -r --name-only origin/HEAD | grep -i pull_request_template` で既定ブランチ側を見る。

**`--body-file` / `--body` を指定すると、テンプレートは適用されない。** `gh` がテンプレートを自動で読み込むのは対話的なエディタ起動時だけで、本文を明示指定した時点で上書きされる。テンプレートの中身を読み、埋めたものを自分でファイルに書いて `--body-file` に渡す。

## PR 作成

```bash
gh pr create --title "<title>" --body-file <file> --base <branch>
```

- `--base` は省略するとリポジトリの既定ブランチ。既定ブランチ以外へ向けるときだけ明示する
- 本文は `--body-file` を使う。`--body` に長い文字列を渡すと改行やバッククォートのエスケープで壊れやすい。一時ファイルは `$TMPDIR` に置き、リポジトリ内に残さない
- 途中段階なら `--draft`
- 作成後に PR 番号・URL を報告する。`--web` でブラウザを開かない（ヘッドレス環境で止まる）

## issue の紐付け

PR 本文に `Closes #123` / `Fixes #123` と書くと、マージ時に issue が自動 close される。単に参照したいだけなら `#123` を裸で書く（close されない）。

commit メッセージ側にも `#123` は書けるが、PR 本文に書くほうが確実で、後から編集できる。

## その他

- CI の確認は `gh pr checks <番号>`、レビューは `gh pr view <番号> --comments`
- issue 作成は `gh issue create`

## 環境固有の注意

`gh pr create` は `claude/hooks/scope-gh-pr-create.sh` により、対象リポジトリの owner が `halkn`（個人アカウント）以外だと確認プロンプトが出る。仕事用リポジトリでは確認を求められるのが正常な動作なので、回避を試みずユーザーの判断を待つ。
