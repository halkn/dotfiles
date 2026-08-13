# native worktree と subagent

## native worktree の扱い

Claude Code は `--worktree` / `EnterWorktree` / subagent の `isolation: worktree` で `<repo>/.claude/worktrees/<name>` に `worktree-<name>` branch の checkout を作る（docs 記載・v2.1.226）。ここは ephemeral・agent-managed の領域で、削除は Claude Code 側（変更なしなら即時、変更があれば `cleanupPeriodDays` に従う sweep）が持つ。人間が継続して使う worktree は `wt` / herdr の領域（`~/.local/share/herdr/worktrees/`）で、両者を同じ場所に集約しない。

- **自己保護は worktree root 基準で再導出される**（v2.1.229・macOS で実測）。cwd が worktree のセッションでは `<worktree>/.claude/**`（`settings.json`・`settings.local.json`・`skills`・`hooks`・`workflows`・`scheduled_tasks.json` 等）と `<worktree>/.mcp.json` が Bash から EPERM で、未存在でも作成できない。main checkout 側の同名パスは絶対パス指定でも別エントリとして塞がれる。この検証は repo 外（`../dotfiles-wt`）と `.claude/worktrees/<name>` の両方で同一の結果
- **保護されないのは repo 側に実体を持つ設定**。`claude/settings.json`・`claude/CLAUDE.md` が main checkout で守られるのは symlink 先保護（`~/.claude/settings.json` の実体だから）によるもので、worktree 内の複製は誰の symlink 先でもないため対象外になる。`claude/` 全体を `sandbox.filesystem.denyWrite` に置いてこの経路を塞いでいる
- **保護は Bash 層のみ**。Bash から EPERM になる `<worktree>/.claude/settings.json` に Edit tool では prompt なしで書ける（v2.1.229・macOS で実測）。保護パスへの Write / Edit は permission system の管轄で、auto モードでは classifier にルーティングされる仕様。worktree で走らせる agent に settings・hook を触らせる作業を渡さず、その diff は merge 前に人間が読む
- **repo 外に worktree を置かない**。`allowRead` は worktree root に解決されるため、main checkout 配下の共有 `.git` が読めず `git rev-parse` すら `not a git repository` で失敗する（v2.1.229・macOS で実測）。`.claude/worktrees/` 配下なら `allowRead: "."` の内側に収まる
- **`git worktree add` を Bash から実行しない**: sandbox は `.zshrc` / `.bashrc` への書込をリポジトリ内のどの階層でも拒否するため、この 2 つを含むこのリポジトリでは checkout が `unable to create file .config/zsh/.zshrc: Operation not permitted` で失敗し、作成途中の worktree だけが残る（v2.1.226 / v2.1.229・macOS で実測）。Claude Code 自身が作る worktree はこの制限を受けない（`isolation: worktree` の subagent が `.config/zsh/.zshrc` を持つ checkout を得られることを確認済み）。worktree が要るときは native の仕組みを使い、人間の作業場は `wt` から作る
- `worktree.baseRef` は `"head"`。既定の `"fresh"` は remote の default branch から分岐するので、herdr worktree の feature branch 上で立てた subagent が作業対象のコミットを持たない。docs も in-progress work を隔離する場合の値として `"head"` を挙げている。worktree 内では**その worktree の HEAD** に解決される
- `.claude/worktrees/` は `.gitignore` に入れる。このリポジトリの `.claude/` は追跡対象なので、入れないと agent の checkout が main checkout に untracked で現れる
- `.worktreeinclude` は**置かない**: gitignored file をコピーする機能だが、このリポジトリの gitignored file は machine-local な identity（`.config/git/config.local`・`.zshenv.local`）と `.config/gh/`（認証情報）で、agent の checkout へ複製すると露出面が広がる。tracked file だけで `mise run lint` は成立する。必要が出たら、複製してよいファイルを個別に列挙してから置く
- native worktree の中で `mise trust` は要らない。mise は linked worktree の config を main checkout の同じパスの trust で扱う（`mise trust --help`・mise 2026.8.3。paranoid mode ではこの共有が切れる）
- `.claude` / `.claude/worktrees` / worktree 自身が symlink だと Claude Code は作成を拒否する。`~/.config` のようにこのリポジトリへ symlink を張る運用を `.claude/` 配下へ広げない

## Subagent の runtime 制御

委譲するかどうかの判断基準は `claude/CLAUDE.md`。ここに置くのは、その基準がどこまで runtime に担保されているか（docs 記載・v2.1.226 時点）。

- **同時実行数**: 既定 20。超えた spawn は `Concurrent subagent limit reached` で失敗し、retry しないよう指示が返る。走っている数が減れば再び通る。session 通算の spawn 数に上限は無い。`CLAUDE_CODE_MAX_CONCURRENT_SUBAGENTS` で変更（v2.1.217 以降。ultracode 有効時は非適用）
- **nesting の深さ**: 既定 3 層。上限に達した subagent からは `Agent` tool が外れる（fork は残るが呼ぶとエラー）。`CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH` で変更、`1` で nesting 無効。既定値はバージョンで動いている（v2.1.172–216 は 5 固定、v2.1.217–218 は 1、v2.1.219 以降 3）ので、この値を前提にした指示を書かない
- **既定は background**（v2.1.198 以降）。結果は後のターンの完了通知で届く。background subagent は built-in tool の集合が縮む（`Read` / `Grep` / `Glob` / `Bash` / `Edit` / `Write` / `WebFetch` / `Skill` 等に限られ、それ以外は `tools` に書いても外れる）。fork は両方のフィルタを受けない
- **fork** は会話・system prompt・tool 構成をそのまま継承する subagent。`/subtask`（v2.1.212 以降。それ以前は `/fork`）。`CLAUDE_CODE_FORK_SUBAGENT=1` にすると全 subagent が background 固定になる

この 2 つの上限を settings の `env` で override しない。既定は runtime 側の安全弁で、こちらが抑えたいのは「利得の無い委譲」という判断の質であって同時実行数ではない。数値を下げると有効な並列作業まで塞ぐ。
