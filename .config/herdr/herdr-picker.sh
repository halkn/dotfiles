#!/bin/zsh
set -euo pipefail

if command -v jaq >/dev/null 2>&1; then
  JQ_BIN=jaq
else
  JQ_BIN=jq
fi

# worktree の一覧・削除ロジックは wt（zsh 関数）に集約し、ここでは再実装しない。
wt_lib=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/worktree.zsh
[[ -r $wt_lib ]] && source "$wt_lib"

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

preview_workspace() {
  local id=$1 workspaces checkout
  workspaces=$(herdr workspace list) || return 0
  print -r -- "$workspaces" \
    | "$JQ_BIN" -r --arg w "$id" '
      .result.workspaces[] | select(.workspace_id == $w)
      | "[\(.number)] \(.label)",
        "agent: \(.agent_status // "-")   tabs: \(.tab_count)   panes: \(.pane_count)"
    '
  print
  print -r -- 'agents:'
  herdr agent list \
    | "$JQ_BIN" -r --arg w "$id" '
      .result.agents[] | select(.workspace_id == $w)
      | "  \(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.terminal_title_stripped // "")"
    '
  checkout=$(
    print -r -- "$workspaces" \
      | "$JQ_BIN" -r --arg w "$id" \
        '.result.workspaces[] | select(.workspace_id == $w) | .worktree.checkout_path // empty'
  )
  if [[ -n $checkout ]] && whence _wt_preview >/dev/null; then
    print
    _wt_preview "$checkout"
  fi
}

# fzf の preview から呼ばれる内部エントリポイント。worktree の表示は wt 側の
# _wt_preview に委譲する。
if [[ ${1:-} == --preview ]]; then
  entry=${2:-}
  [[ -n $entry ]] || exit 0
  case ${entry%%:*} in
    agent) herdr agent read "${entry#*:}" --source recent --lines "${FZF_PREVIEW_LINES:-40}" --format ansi 2>/dev/null ;;
    worktree) whence _wt_preview >/dev/null && _wt_preview "${entry#*:}" ;;
    workspace) preview_workspace "${entry#*:}" ;;
  esac
  exit 0
fi

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
default_mode=workspace

# reload() で自分自身を呼び出して各モードの一覧を出力するための内部エントリポイント
if [[ ${1:-} == --list ]]; then
  list_for_mode "$2"
  exit 0
fi

# ctrl-x:transform() から呼ばれ、worktree モードのときだけ選択中の worktree を削除する。
# 未コミット変更があると git worktree remove が失敗するため、確認プロンプト無しでも安全側に倒れる。
if [[ ${1:-} == --remove ]]; then
  [[ $(<"$HERDR_PICKER_STATE") == worktree ]] || exit 0
  target=${2#worktree:}
  [[ -n $target ]] || exit 0
  if ! whence _wt_remove_external >/dev/null; then
    printf 'change-header(worktree.zsh not found)\n'
    exit 0
  fi
  if message=$(_wt_remove_external "$target" 0 2>&1); then
    printf 'reload(%s --list worktree)+change-header(removed %s)\n' "$self" "${target:t}"
  else
    printf 'change-header(%s)\n' "${message//[()]/ }"
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
      --height=100% \
      --style=full --border-label=" herdr " --prompt="$(prompt_for_mode "$default_mode")" \
      --header 'Tab: switch workspaces / agents / worktrees | worktrees: ctrl-x remove' \
      --preview "$self --preview {2}" \
      --preview-window 'down:60%:wrap' \
      --bind "tab:transform:$self --cycle" \
      --bind "ctrl-x:transform:$self --remove {2}"
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
