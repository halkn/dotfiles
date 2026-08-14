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

# Internal entry point, called by the tv preview.
if [[ ${1:-} == --preview ]]; then
  entry=${2:-}
  [[ -n $entry ]] || exit 0
  case ${entry%%:*} in
    agent)
      herdr agent read "${entry#*:}" --source recent --lines 40 --format ansi 2>/dev/null
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

# Internal entry point, called by the channel to list one mode.
if [[ ${1:-} == --list ]]; then
  list_for_mode "$2"
  exit 0
fi

# Internal entry point, called by the ctrl-x action. No confirmation prompt is
# needed: `git worktree remove` refuses a checkout that still holds uncommitted
# work. Anything but a worktree row is ignored, since the same key is live in
# every mode.
if [[ ${1:-} == --remove ]]; then
  entry=${2:-}
  [[ $entry == worktree:* ]] || exit 0
  target=${entry#worktree:}
  [[ -n $target ]] || exit 0
  if ! whence _wt_remove_external >/dev/null; then
    print -u2 'herdr-picker: worktree.zsh not found'
    exit 0
  fi
  _wt_remove_external "$target" 0 || true
  exit 0
fi

command -v tv >/dev/null 2>&1 || {
  print -u2 'herdr-picker: tv is not installed'
  exit 1
}

# The channel prints `<mode>:<target>`; which list it came from decides what
# focusing it means.
selected=$(tv herdr) || exit 0
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
