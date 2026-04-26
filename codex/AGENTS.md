# 開発スタイル

TDD で開発する（探索 → Red → Green → Refactoring）。
ただし、設定ファイル・ドキュメント・小規模な修正では、対象に合った最小の検証を優先する。
KPI やカバレッジ目標が与えられたら、達成するまで試行する。達成不能な場合は、原因・試したこと・次の選択肢を報告する。
不明瞭な指示は質問して明確にする。。

# コード設計

- 関心の分離を保つ
- 状態とロジックを分離する
- 可読性と保守性を重視する
- コントラクト層（API/型）を厳密に定義し、実装層は再生成可能に保つ
- 静的検査可能なルールはプロンプトではなく、その環境の linter か ast-grep で記述する

# ツール

- python: uv/ruff/pyright
- shell: shfmt/shellcheck
- 検索は rg を優先する

# 言語

- 回答は日本語を優先する
- 公開リポジトリではドキュメントやコミットメッセージを英語で記述する

# 環境

- GitHub: {{ .github_username }}
- リポジトリ: ghq 管理（`~/dev/github.com/owner/repo`）

# スキル作成

新規 skill を作るとき、配置先を次の指針で決める:

- **Codex グローバル** (`~/.codex/skills/`): Codex で複数 repo に再利用する
- **Claude グローバル** (`~/.claude/skills/`): Claude で複数 repo に再利用する
- **project 固有** (`<repo>/.codex/skills/` または `<repo>/.claude/skills/`): 特定 repo のドメイン知識・規約・ファイルレイアウトに依存し、他 repo で使う見込みがない
- **判断不能なとき**: ユーザーに「project 固有かグローバルか」「Codex 用か Claude 用か」を質問してから作成（理由: 後から移動するとパス参照が壊れやすい）
