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

list_for_mode() {
  case $1 in
    workspace) list_workspaces ;;
    agent) list_agents ;;
    worktree) list_worktrees ;;
  esac
}

prompt_for_mode() {
  case $1 in
    workspace) print -r -- 'workspaces> ' ;;
    agent) print -r -- 'agents> ' ;;
    worktree) print -r -- 'worktrees> ' ;;
  esac
}

next_mode() {
  case $1 in
    agent) print -r -- workspace ;;
    workspace) print -r -- worktree ;;
    worktree) print -r -- agent ;;
  esac
}

self=${0:A}
default_mode=agent

# reload() で自分自身を呼び出して各モードの一覧を出力するための内部エントリポイント
if [[ ${1:-} == --list ]]; then
  list_for_mode "$2"
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
      --header 'Tab: switch workspaces / agents / worktrees' \
      --preview '
        entry={2}
        mode=${entry%%:*}
        target=${entry#*:}
        case "$mode" in
          agent) herdr agent read "$target" --source recent --lines 60 --format ansi 2>/dev/null ;;
          worktree) eza --tree --color=always "$target" 2>/dev/null ;;
          workspace) printf "workspace: %s\n" "$target" ;;
        esac
      ' \
      --preview-window right:50% \
      --bind "tab:transform:$self --cycle"
) || exit 0

mode_target=$(printf '%s' "$selected" | awk -F'\t' '{print $2}')
[[ -n $mode_target ]] || exit 0
mode=${mode_target%%:*}
target=${mode_target#*:}

case $mode in
  workspace) herdr workspace focus "$target" ;;
  agent) herdr agent focus "$target" ;;
  worktree) herdr worktree open --path "$target" --focus ;;
esac
