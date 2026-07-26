#!/bin/zsh
set -euo pipefail

if command -v jaq >/dev/null 2>&1; then
  JQ_BIN=jaq
else
  JQ_BIN=jq
fi

list_workspaces() {
  herdr workspace list \
    | "$JQ_BIN" -r '.result.workspaces[] | "[\(.number)] \(.label)\tworkspace:\(.workspace_id)"'
}

list_agents() {
  herdr agent list \
    | "$JQ_BIN" -r '.result.agents[] | "\(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.cwd // "-")\tagent:\(.terminal_id)"'
}

list_worktrees() {
  herdr worktree list --json \
    | "$JQ_BIN" -r '.result.worktrees[] | "\(.label)  \(.branch // "-")  \(.path)\tworktree:\(.path)"'
}

# popup の cwd がリポジトリ外だったり gh 未認証だったりしても picker 全体を落とさない
list_prs() {
  local out
  out=$(
    gh pr list --limit 100 \
      --json number,title,author,headRefName,isDraft \
      --jq '.[] | "#\(.number)  \(if .isDraft then "draft" else "open " end)  \(.author.login)  \(.title)\tpr:\(.number)"' \
      2>/dev/null
  ) || out=''
  if [[ -z $out ]]; then
    print -r -- $'(no pull requests here)\tnoop:'
  else
    print -r -- "$out"
  fi
}

list_for_mode() {
  case $1 in
    workspace) list_workspaces ;;
    agent) list_agents ;;
    worktree) list_worktrees ;;
    pr) list_prs ;;
  esac
}

prompt_for_mode() {
  case $1 in
    workspace) print -r -- 'workspaces> ' ;;
    agent) print -r -- 'agents> ' ;;
    worktree) print -r -- 'worktrees> ' ;;
    pr) print -r -- 'prs> ' ;;
  esac
}

next_mode() {
  case $1 in
    workspace) print -r -- worktree ;;
    worktree) print -r -- pr ;;
    pr) print -r -- agent ;;
    agent) print -r -- workspace ;;
  esac
}

self=${0:A}
default_mode=workspace

# reload() で自分自身を呼び出して各モードの一覧を出力するための内部エントリポイント
if [[ ${1:-} == --list ]]; then
  list_for_mode "$2"
  exit 0
fi

# ctrl-x の reload() 用。今どのモードかは state file にしか無いのでここで読み直す
if [[ ${1:-} == --list-state ]]; then
  list_for_mode "$(<"$HERDR_PICKER_STATE")"
  exit 0
fi

# ctrl-x から呼ばれる。worktree 以外のモードでは何もしない。
# 削除の可否判定（未コミット / 未 push）は git-wt 側に任せる
if [[ ${1:-} == --remove ]]; then
  payload=${2:-}
  if [[ $payload == worktree:* ]]; then
    git-wt rm --path "${payload#worktree:}" || true
    print -n 'press any key to continue' >&2
    read -r -k1
  fi
  exit 0
fi

# tab:transform() から呼ばれ、現在モードを次に進めつつ reload+change-prompt 用のバインド式を出力する
if [[ ${1:-} == --cycle ]]; then
  current=$(<"$HERDR_PICKER_STATE")
  next=$(next_mode "$current")
  print -r -- "$next" >"$HERDR_PICKER_STATE"
  printf 'reload(%s --list %s)+change-prompt(%s)+first\n' "$self" "$next" "$(prompt_for_mode "$next")"
  exit 0
fi

state_file=$(mktemp "${TMPDIR:-/tmp}/herdr-picker.XXXXXX")
trap 'rm -f "$state_file"' EXIT
print -r -- "$default_mode" >"$state_file"
export HERDR_PICKER_STATE=$state_file

selected=$(
  list_for_mode "$default_mode" \
    | fzf --delimiter '\t' --with-nth 1 --ansi \
      --style=full --border-label=" herdr " --prompt="$(prompt_for_mode "$default_mode")" \
      --header 'Tab: workspaces / worktrees / prs / agents   ctrl-x: remove worktree' \
      --preview '
        entry={2}
        mode=${entry%%:*}
        target=${entry#*:}
        case "$mode" in
          agent) herdr agent read "$target" --source recent --lines 60 --format ansi 2>/dev/null ;;
          worktree)
            git -C "$target" status --short --branch 2>/dev/null
            echo
            git -C "$target" log --oneline --decorate --color=always -20 2>/dev/null
            ;;
          pr) gh pr view "$target" --comments 2>/dev/null ;;
          workspace) printf "workspace: %s\n" "$target" ;;
        esac
      ' \
      --preview-window right:50% \
      --bind "tab:transform:$self --cycle" \
      --bind "ctrl-x:execute($self --remove {2})+reload($self --list-state)"
) || exit 0

mode_target=$(printf '%s' "$selected" | awk -F'\t' '{print $2}')
[[ -n $mode_target ]] || exit 0
mode=${mode_target%%:*}
target=${mode_target#*:}

case $mode in
  workspace) herdr workspace focus "$target" ;;
  agent) herdr agent focus "$target" ;;
  worktree) herdr worktree open --path "$target" --focus ;;
  pr)
    # レビュー用 worktree を払い出して workspace として開く
    dir=$(git-wt pr "$target") || exit 1
    [[ -n $dir ]] || exit 0
    herdr worktree open --path "$dir" --focus
    ;;
esac
