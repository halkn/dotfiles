# ui - what the scripts in .config/herdr/ share: the dependency check, the popup
# prompts, the chrome of a full-screen picker, and the previews. Asking herdr
# anything is `hw`'s, not this file's.
#
# It sources nothing itself, which is what lets an fzf preview - a fresh shell -
# source it alone.

_UI_LIB=${${(%):-%x}:A}

# The command name is passed in so the message names what the user typed, not
# the file the check lives in.
_ui_require() {
  local tool=${1:-} cmd=${2:-}
  command -v "$tool" >/dev/null 2>&1 || {
    print "$cmd: $tool is not installed" >&2
    return 1
  }
}

# A popup closes as soon as its command ends, taking what was printed with it.
_ui_pause() {
  print -n 'press any key '
  read -rsk1 || true
}

_ui_die() {
  local cmd=${1:-} msg=${2:-}
  [[ -z $msg ]] || print -u2 "$cmd: $msg"
  _ui_pause
  exit 1
}

_ui_confirm() {
  print -n "$1 [y/N] "
  read -rq && {
    print
    return 0
  }
  print
  return 1
}

# Not FZF_DEFAULT_OPTS, which is sized for a completion popped up under the
# cursor: these pickers are the window while they are open, and the herdr popup
# they also run in is too narrow for a preview beside the list.
#
# The border label is left to the caller, which names it after the command the
# picker belongs to rather than after the file the chrome lives in.
typeset -ga _UI_FZF_CHROME=(
  --height=100%
  --style=full
  --preview-window 'down:60%:wrap'
)

# A row that is a directory. One that is not a checkout still gets a listing.
_ui_git_preview() {
  local dir=${1:-}
  [[ -n $dir ]] || return 0
  dir=${dir:A}
  print -r -- "$dir"
  [[ -d $dir ]] || {
    print 'missing'
    return 0
  }
  print
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$dir" -c color.ui=always status --short --branch 2>/dev/null || true
    print
    git -C "$dir" log --oneline --decorate --color=always -15 2>/dev/null || true
  else
    ls -A -- "$dir" 2>/dev/null | head -30 || true
  fi
  # A directory git refuses is still a preview, not a failure.
  return 0
}

# A row that is a branch of the repository here, local or only on origin.
_ui_branch_preview() {
  local branch=${1:-} ref
  [[ -n $branch ]] || return 0
  for ref in "refs/heads/$branch" "refs/remotes/origin/$branch"; do
    git rev-parse -q --verify "$ref" >/dev/null 2>&1 || continue
    git log --oneline --decorate --color=always -15 "$ref" 2>/dev/null || true
    return 0
  done
  print 'a new branch from HEAD'
}
