---
description: このリポジトリの Claude Code 設定（claude/settings.json・.claude/settings.json・claude/hooks/・sandbox・permissions・PreToolUse hook・excludedCommands・native worktree・subagent の runtime 上限）を監査・変更するときの根拠の取り方と実測記録。sandbox の allowRead/denyRead や permissions の allow/deny/ask を見直す、hook を足す・消す、auto モードの挙動を確認する、といった作業で使う。
---

# Claude Code 設定の監査

判断基準そのものは `.claude/rules/claude-code.md`。ここに置くのは、その基準を確かめるための手順と、確認済みの実測記録。

## 手順

1. 変更対象キーの現状値を `claude/settings.json` と `.claude/settings.json` で確認する。このリポジトリは既に設定済みの範囲が広く、現状を見ずに書くと重複や矛盾した提案になる
1. references の該当箇所を読む。**検討して採用しなかった**設定も記録してあるので、再提案する前に確認する
1. hook や permissions を触るなら `claude auto-mode defaults` で既定の classifier ルールを読む。実行可否は `which` で判定せず直接叩いて確かめる（PATH に出なくても実行できることがある）。実際に失敗したときだけ references の記録で代替し、応答に「既定ルールは未確認」と明示する
1. 変更後は新規セッションで、意図した allow / deny が効いていることを実際のコマンドで確かめる
1. `mise run lint` を通す。read を狭める変更はツールが黙って既定値で動くだけのことがあり、壊れたことが結果の変化としてしか出ない

## 根拠の取り方

- `claude/settings.json` の監査・変更は公式 docs（code.claude.com/docs）と CHANGELOG を根拠にする。`$schema` が指す schemastore 定義は追従が遅く（`sandbox`・`fileSuggestion` 等が未収録）、キーの有効性判断には使わない
- references の「実測済み」記述にはバージョンを添えてある。`claude --version` と突き合わせ、patch 差（v2.1.226 → v2.1.229 等）はそのまま従ってよい。minor が上がっていたら docs と再測定で裏を取り直す。認証情報と sandbox 境界に関わる変更だけは、差が小さくても手順 4 で実際に効いていることを確かめる
- sandbox の実測は macOS（Seatbelt）と WSL2（bubblewrap）で別に取る。実装が違うので片方の結果を他方へ一般化しない。バージョンだけ書かれていてプラットフォームが書かれていない記述は macOS のものとして扱う
- sandbox の挙動を測るときは `~/.claude/settings.json` を書き換えず、`claude --settings <file> -p` の使い捨てセッションで測る。ただし配列はスコープ間でマージされるので、この方法で **allow を狭めることはできない**（deny の追加だけができる）。`CLAUDE_CONFIG_DIR` を差し替える方法は OAuth を引けず（`Not logged in`）使えない
- サンドボックス内から起動した `claude` は keychain を読めないので、probe セッションは Claude Code の外側のターミナルから実行する
- `sandbox` を変更したら**新規セッション**で効果を確認する。作業中のセッションは変更前のポリシーで動き続けることがあるので、そこでの結果を根拠にしない

## References

手順 2 でどれを開くかは、扱う対象で決める。

- [sandbox-permissions.md](references/sandbox-permissions.md): allowRead / denyRead / credentials を足す・削る、deny が効かない、`excludedCommands` を増やす、`permissions` のパターンが意図通り当たらない、auto モードで allow が無視される
- [hooks.md](references/hooks.md): hook を足す・消す・書き換える、hook が黙って発火しない、`credentials.envVars` を追加する
- [worktree-subagent.md](references/worktree-subagent.md): `isolation: worktree` の subagent に何を任せるか、`git worktree add` を打つ、`.claude/worktrees/` の掃除、subagent の同時実行数・nesting の上限
