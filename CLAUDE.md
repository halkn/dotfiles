# CLAUDE.md

@AGENTS.md

以下は Claude Code でのみ意味を持つ補足。

- `.claude/rules/` と `.claude/skills/` はこのリポジトリ自身の設定で symlink されない。新規ファイルは登録なしで次のセッションから対象になる
- `paths:` を持つ rule は、一致するファイルを Read tool で開いたときだけ context に載る。`cat` / `sed` で読み書きするセッションには届かないので、AGENTS.md の Scoped guidance で名指しされたファイルは作業前に Read で開く
- `.claude/rules/` の path-scoped ルールを `~/.claude/rules/` へ移さない。user-level でも `paths:` は一致するが、glob の基準が cwd なので他のリポジトリでも当たる。全プロジェクト共通のルールは `claude/CLAUDE.md` に直接書く
