# ui - what every picker in .config/herdr/ shares: the dependency check, the chrome
# of a full-screen picker, and the preview of a directory.
#
# lib/ files never source each other or anything in workflows/, which is what
# lets an fzf preview - a fresh shell - source one of them alone.

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

# Every row a picker offers is a directory, so one preview covers all of them.
# A directory that is not a checkout still gets a listing.
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
  # A directory git refuses must not end the preview process, which runs under
  # `set -e` in the herdr picker.
  return 0
}
