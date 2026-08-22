#!/bin/zsh
set -euo pipefail

# Listing, previewing, opening and removing lives in `wt` (`repo.zsh` is what
# puts the repositories in that listing); do not reimplement any of it here.
zsh_workflows=${XDG_CONFIG_HOME:-$HOME/.config}/zsh/workflows
for lib in repo.zsh worktree.zsh; do
  if [[ -r $zsh_workflows/$lib ]]; then
    source "$zsh_workflows/$lib"
  fi
done

list_agents() {
  herdr agent list \
    | jq -r '.result.agents[] | "\(.agent_status)  \(.name // .display_agent // .agent // "agent")  \(.cwd // "-")\tagent:\(.terminal_id)"'
}

# Internal entry point, called by the fzf preview.
if [[ ${1:-} == --preview ]]; then
  entry=${2:-}
  [[ -n $entry ]] || exit 0
  case ${entry%%:*} in
    agent)
      herdr agent read "${entry#*:}" --source recent --lines "${FZF_PREVIEW_LINES:-40}" --format ansi 2>/dev/null
      ;;
    *)
      whence _wt_nav_preview >/dev/null && _wt_nav_preview "$entry"
      ;;
  esac
  exit 0
fi

# Workspaces, worktrees and repositories are one list: they are all somewhere to
# go, and the same checkout used to show up in several of them. Agents are a
# mode of their own because focusing one is a different question.
list_for_mode() {
  case $1 in
    place)
      whence _wt_nav_rows >/dev/null && _wt_nav_rows
      ;;
    agent)
      list_agents
      ;;
  esac
}

prompt_for_mode() {
  case $1 in
    place)
      print -r -- 'go> '
      ;;
    agent)
      print -r -- 'agents> '
      ;;
  esac
}

next_mode() {
  case $1 in
    place)
      print -r -- agent
      ;;
    agent)
      print -r -- place
      ;;
  esac
}

self=${0:A}
default_mode=place

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
  [[ -n $entry ]] || exit 0
  if ! whence _wt_remove_external >/dev/null; then
    printf 'change-header(worktree.zsh not found)\n'
    exit 0
  fi
  # A repository row is its main checkout, which is never removable; an open
  # worktree hides behind a workspace row, so the path has to be resolved.
  [[ $entry != repo:* ]] || exit 0
  target=$(_wt_nav_checkout_path "$entry")
  [[ -n $target ]] || exit 0
  if message=$(_wt_remove_external "$target" 0 2>&1); then
    printf 'reload(%s --list place)+change-header(removed %s)\n' "$self" "${target:t}"
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

# Every row carries `<kind>:<target>` in its second field: going there means
# something else per kind.
selected=$(
  list_for_mode "$default_mode" \
    | fzf --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
      --height=100% \
      --style=full --border-label=" herdr " --prompt="$(prompt_for_mode "$default_mode")" \
      --header 'Tab: switch places / agents | places: ctrl-x remove a worktree' \
      --preview "$self --preview {2}" \
      --preview-window 'down:60%:wrap' \
      --bind "tab:transform:$self --cycle" \
      --bind "ctrl-x:transform:$self --remove {2}"
) || exit 0
[[ -n $selected ]] || exit 0

if [[ $selected == agent:* ]]; then
  herdr agent focus "${selected#agent:}"
  exit 0
fi
whence _wt_nav_open >/dev/null && _wt_nav_open "$selected"
