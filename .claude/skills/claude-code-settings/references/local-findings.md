# このリポジトリ固有の findings

再発見のコストが高く、公式 docs にも `--help` にも出てこないものだけを置く。Claude Code 一般の仕様はここに複製しない。記録時のバージョンを添えてあるので、`claude --version` と突き合わせて minor が上がっていたら測り直す。

## `~/.config` が symlink であること

- `~/.config` はこのリポジトリへの symlink。sandbox の判定は**解決後のパス**で行われるため、`~/.config/<name>` 表記の deny は dir 単位でも file 単位でも効かない（実体が `allowRead: "."` の内側にある）。逆に `~/.config` を allowRead から外して配下だけ列挙する形も、symlink 本体が辿れず効かない。閉じたいものは実体パス（`~/repos/.../.config/gh`）で書き、symlink でない機械のために `~/.config/gh` 表記も併記する（v2.1.226 で実測）
- 同じ理由で、`~/.claude/skills/<name>` を別リポジトリへの symlink にすると判定が解決後の実パスに移り、symlink 先が別途 `allowRead` に無いと Bash から読めない（v2.1.267）。`gh skill install --scope user -f` は symlink をそのまま辿って symlink 先リポジトリの実ファイルを上書きするので、実体コピーへ切り替えるときはインストール前に symlink を消す（Claude Code の外のターミナルで行う。`~/.claude/skills` への write は自己保護で拒否される）

## repo 側に実体を持つ設定の保護

- Claude Code の自己保護は、それ自身がロードするパスとそこから張られた symlink の先にしか届かない。`claude/hooks/*.sh`・`claude/statusline-command.sh` は Claude Code が実行するが symlink 先ではないので対象外で、Bash から書けた（v2.1.229・macOS）。`claude/` を `sandbox.filesystem.denyWrite` に実体パスで列挙して塞いでいる
- その副作用として、`claude/` 配下を変更する `git merge` / `git switch` は sandbox 内で `unable to unlink old` になる（docs の Troubleshooting 記載）。`mise.toml` は日常的に編集するので deny に置かず classifier に委ねている

## ログインシェルが読むキャッシュ

- `.zshrc` は `$XDG_CACHE_HOME` 配下のファイルを起動時に source し、`compinit -C` は `.zcompdump` を検査なしで読む。つまり `~/.cache` への書込は sandbox 外・classifier 外で次のシェル起動時に実行される。`~/.cache` を丸ごと allowWrite にして例外を deny で列挙する形は fail-open になるので採らない。ツール別の列挙を維持する（v2.1.259・macOS）

## mise との相互作用

- `mise bootstrap --dry-run` の差分は、`[dotfiles]` の配置先が全て allowRead に入っていないと信用できない。`~/.zshenv` のように denyRead 配下にあるターゲットは lstat が EPERM になり、mise はそれを「symlink 未作成」と見なして差分に出す。**エラーにならないので気づきにくい**。`[dotfiles]` にターゲットを足したら配置先を allowRead にも足す（v2.1.226・mise 2026.8.3）
- `mise bootstrap` は `--dry-run` / `status` でも `[bootstrap.repos]` の clone 先を読む。allowRead に無いと repos ステップだけが `Operation not permitted` で落ちるので、permission と sandbox のどちらで止まったかを切り分けてから直す
- `allowRead` を削ったら `mise run lint` を通す。ツールは自分の設定を読めなくなっても多くは失敗せず、黙って既定値で動く。壊れたことが結果の変化としてしか出ない

## excludedCommands

- `gh *` の除外は維持する。sandbox 内では keyring のトークンを引けず、TLS 検証も通らない 2 系統で壊れる（v2.1.226・macOS）。監査のたびに再検討しない
- 除外はコマンド文字列へのマッチなので、`bash script.sh` の中から `gh` を呼ぶと除外は効かない。スクリプト経由で `gh` を使わない
- `git` はネットワーク／認証を要するサブコマンドだけを除外する。`git *` 全体を除外すると `denyRead` が git 経由で素通しになる
- hunk の session daemon は loopback の websocket broker で、sandbox 内からは connect() が拒否される。outbound loopback を許可するキーは無いので除外に残す（v2.1.251・hunk 0.20.0）。到達性の判定に `hunk session list` の出力を使わない: 存在しないポートを指しても同じ「No active Hunk sessions.」を返す

## hook の登録方法

- PreToolUse hook の `command` にスクリプトパスを直接書かない。不在時は exit 127 の non-blocking error になり、ガードが無言で失効する。`h=<path>; [ -x "$h" ] || { echo ... >&2; exit 2; }; exec "$h"` の形で包む。`claude/hooks/` へ追加したスクリプトは `mise bootstrap` を実行するまで `~/.claude/hooks/` に symlink されないため、この失効は容易に起きる
- PreToolUse hook に `if` フィルタ（permission rule 構文）を使わない。prefix マッチのため複合コマンド（`git push && gh pr create ...`）で hook 自体がスキップされ、スクリプト側のセグメント解析が無効化される
- 現行 hook それぞれの存在理由と既知の抜け道は `claude/hooks/*.sh` の冒頭コメントにある

## worktree

- `git worktree add` を Bash から実行しない。sandbox は `.zshrc` / `.bashrc` への書込をリポジトリ内のどの階層でも拒否するため、この 2 つを持つこのリポジトリでは checkout が途中で失敗し、作りかけの worktree だけが残る（v2.1.229・macOS）。Claude Code 自身が作る worktree はこの制限を受けない
- repo 外に worktree を置かない。`allowRead` が worktree root に解決され、main checkout 配下の共有 `.git` が読めず `git rev-parse` すら失敗する
- `worktree.baseRef` は `"head"`。既定の `"fresh"` は remote の default branch から分岐するので、feature branch 上で立てた subagent が作業対象のコミットを持たない
- `.worktreeinclude` は置かない。このリポジトリの gitignored file は machine-local な identity と認証情報で、agent の checkout へ複製すると露出面が広がる。tracked file だけで `mise run lint` は成立する
- `.claude/worktrees/` を `.gitignore` に入れる。このリポジトリの `.claude/` は追跡対象なので、入れないと agent の checkout が untracked で現れる

## 指示のロード条件

- `paths:` を持つ rule とサブディレクトリの `CLAUDE.md` は、Read tool が一致するファイルを開いた時点でだけ context に載る。Bash（`cat` / `sed`）・Grep・Edit・Write は契機にならない。user-level（`~/.claude/rules/`）の `paths:` も同様に効くが、glob の基準が cwd になる（v2.1.273・Linux で実測）
- 確かめ方: `paths:` 付きの rule に合言葉を書いた repro を作り、`claude -p --allowedTools=Read` と `--allowedTools=Bash`（`cat`）で同じファイルを読ませて出力を比べる。`--allowedTools` は可変長引数なので `=` で繋がないとプロンプトを飲み込む
- auto / bypassPermissions のセッションには Bash 優先の指示が注入されることがあり、そうなるとこのロードも file tool の hook も黙って効かなくなる

## 採用しない設定（再提案しない。根拠は各 commit にある）

`env.CLAUDE_CODE_SUBPROCESS_ENV_SCRUB`（Bash tool が広範に壊れる）、`~/.cache` を丸ごと allow して例外を `denyWrite` で列挙する形（fail-open）、`sandbox.network.tlsTerminate` と `credentials.envVars` の `mode: "mask"`、`az *` の `excludedCommands` 除外（`strictAllowlist` を迂回する egress 経路になる）、`env.CLAUDE_CODE_THRIFTY_SONIC`（未文書化フラグで副作用を確かめられない）、subagent の同時実行数・nesting 上限の `env` override（runtime 側の安全弁）。
