# ui - what every picker in workflows/ shares: the dependency check, the chrome
# of a full-screen picker, and the preview of a directory.
#
# lib/ files hold no command and no `cd`: they answer questions about one kind
# of information. They never source each other or anything in workflows/, which
# is what lets an fzf preview - a fresh shell - source one of them alone.

_UI_LIB=${${(%):-%x}:A}

# `<command>: <tool> is not installed` on stderr, non-zero when the tool is
# missing. The command name is passed in because the message names the command
# the user typed, not the file the check lives in.
_ui_require() {
  local tool=${1:-} cmd=${2:-}
  command -v "$tool" >/dev/null 2>&1 || {
    print "$cmd: $tool is not installed" >&2
    return 1
  }
}

# The pickers take the whole screen with the preview under the list.
# FZF_DEFAULT_OPTS is sized for a completion popped up under the cursor, which
# is not what these are: they are the window while they are open, and the herdr
# popup they also run in is too narrow for a preview beside the list.
typeset -ga _UI_FZF_CHROME=(
  --height=100%
  --style=full
  --border-label=' wk '
  --preview-window 'down:60%:wrap'
)

# Every row a picker in workflows/ offers is a directory, so one preview covers
# all of them. A directory that is not a checkout still gets a listing, since
# `wk open` offers those too.
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
    git -C "$dir" -c color.ui=always status --short --branch 2>/dev/null
    print
    git -C "$dir" log --oneline --decorate --color=always -15 2>/dev/null
  else
    ls -A -- "$dir" 2>/dev/null | head -30
  fi
  # A directory git refuses must not end the preview process, which runs under
  # `set -e` in the herdr picker.
  return 0
}
