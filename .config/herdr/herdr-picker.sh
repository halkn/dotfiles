#!/bin/zsh
set -euo pipefail

# Listing and removing worktrees lives in `wt`; do not reimplement either here.
wt_lib=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows/worktree.zsh
[[ -r $wt_lib ]] && source "$wt_lib"

list_workspaces() {
  herdr workspace list \
    | jq -r '.result.workspaces[] | "[\(.number)] \(.label)\tworkspace:\(.workspace_id)"'
}

list_agents() {
  herdr agent list \
    | jq -r '.result.agents[] | "\(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.cwd // "-")\tagent:\(.terminal_id)"'
}

list_worktrees() {
  herdr worktree list --json \
    | jq -r '.result.worktrees[] | "\(.label)  \(.branch // "-")  \(.path)\tworktree:\(.path)"'
}

preview_workspace() {
  local id=$1 workspaces checkout
  workspaces=$(herdr workspace list) || return 0
  print -r -- "$workspaces" \
    | jq -r --arg w "$id" '
      .result.workspaces[] | select(.workspace_id == $w)
      | "[\(.number)] \(.label)",
        "agent: \(.agent_status // "-")   tabs: \(.tab_count)   panes: \(.pane_count)"
    '
  print
  print -r -- 'agents:'
  herdr agent list \
    | jq -r --arg w "$id" '
      .result.agents[] | select(.workspace_id == $w)
      | "  \(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.terminal_title_stripped // "")"
    '
  checkout=$(
    print -r -- "$workspaces" \
      | jq -r --arg w "$id" \
        '.result.workspaces[] | select(.workspace_id == $w) | .worktree.checkout_path // empty'
  )
  if [[ -n $checkout ]] && whence _wt_preview >/dev/null; then
    print
    _wt_preview "$checkout"
  fi
}

# Internal entry point, called by the fzf preview.
if [[ ${1:-} == --preview ]]; then
  entry=${2:-}
  [[ -n $entry ]] || exit 0
  case ${entry%%:*} in
    agent)
      herdr agent read "${entry#*:}" --source recent --lines "${FZF_PREVIEW_LINES:-40}" --format ansi 2>/dev/null
      ;;
    worktree)
      whence _wt_preview >/dev/null && _wt_preview "${entry#*:}"
      ;;
    workspace)
      preview_workspace "${entry#*:}"
      ;;
  esac
  exit 0
fi

list_for_mode() {
  case $1 in
    workspace)
      list_workspaces
      ;;
    agent)
      list_agents
      ;;
    worktree)
      list_worktrees
      ;;
  esac
}

prompt_for_mode() {
  case $1 in
    workspace)
      print -r -- 'workspaces> '
      ;;
    agent)
      print -r -- 'agents> '
      ;;
    worktree)
      print -r -- 'worktrees> '
      ;;
  esac
}

next_mode() {
  case $1 in
    workspace)
      print -r -- worktree
      ;;
    worktree)
      print -r -- agent
      ;;
    agent)
      print -r -- workspace
      ;;
  esac
}

self=${0:A}
default_mode=workspace

# Internal entry point, called by reload() to re-list one mode.
if [[ ${1:-} == --list ]]; then
  list_for_mode "$2"
  exit 0
fi

# Internal entry point, called by tab:transform(). The mode lives in a file
# because each transform runs in its own process.
if [[ ${1:-} == --cycle ]]; then
  current=$(<"$HERDR_PICKER_STATE")
  next=$(next_mode "$current")
  print -r -- "$next" >"$HERDR_PICKER_STATE"
  printf 'reload(%s --list %s)+change-prompt(%s)+first\n' "$self" "$next" "$(prompt_for_mode "$next")"
  exit 0
fi

# Internal entry point, called by the ctrl-x binding. No confirmation prompt is
# needed: `git worktree remove` refuses a checkout that still holds uncommitted
# work. The key is live in every mode, so other rows are ignored here.
if [[ ${1:-} == --remove ]]; then
  entry=${2:-}
  [[ $entry == worktree:* ]] || exit 0
  target=${entry#worktree:}
  [[ -n $target ]] || exit 0
  if ! whence _wt_remove_external >/dev/null; then
    printf 'change-header(worktree.zsh not found)\n'
    exit 0
  fi
  if message=$(_wt_remove_external "$target" 0 2>&1); then
    printf 'reload(%s --list worktree)+change-header(removed %s)\n' "$self" "${target:t}"
  else
    # Parentheses would end the action's argument list.
    printf 'change-header(%s)\n' "${message//[()]/ }"
  fi
  exit 0
fi

command -v fzf >/dev/null 2>&1 || {
  print -u2 'herdr-picker: fzf is not installed'
  exit 1
}

state_file=$(mktemp "${TMPDIR:-/tmp}/herdr-picker.XXXXXX")
trap 'rm -f "$state_file"' EXIT
print -r -- "$default_mode" >"$state_file"
export HERDR_PICKER_STATE=$state_file

# Every row carries `<mode>:<target>` in its second field: focusing means
# something else per mode.
selected=$(
  list_for_mode "$default_mode" \
    | fzf --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
      --height=100% \
      --style=full --border-label=" herdr " --prompt="$(prompt_for_mode "$default_mode")" \
      --header 'Tab: switch workspaces / worktrees / agents | worktrees: ctrl-x remove' \
      --preview "$self --preview {2}" \
      --preview-window 'down:60%:wrap' \
      --bind "tab:transform:$self --cycle" \
      --bind "ctrl-x:transform:$self --remove {2}"
) || exit 0
[[ -n $selected ]] || exit 0
mode=${selected%%:*}
target=${selected#*:}

case $mode in
  workspace)
    herdr workspace focus "$target"
    ;;
  agent)
    herdr agent focus "$target"
    ;;
  worktree)
    herdr worktree open --path "$target" --focus
    ;;
esac
