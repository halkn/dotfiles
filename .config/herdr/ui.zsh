# ui - what the scripts in .config/herdr/ share: the dependency check, the popup
# prompts, the chrome of a full-screen picker, the preview of a directory, and
# the rows of the open workspaces.
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

# `<display>\t<workspace id>\t<path>` per open workspace. herdr 0.9.1 gives a
# path only to a workspace on a git checkout; the others show their label alone.
# A path under either root reads as what it is - <owner>/<repo>/<branch> or
# <host>/<owner>/<repo> - and anything else keeps its full path.
_ui_workspaces() {
  local out rows row dir shown wt_root repo_root
  local -a f
  out=$(herdr workspace list) || return 1
  rows=$(print -r -- "$out" | jq -r '
    .result.workspaces[]?
    | [.workspace_id, (.number | tostring), .label, (.worktree.checkout_path // "")]
    | @tsv
  ') || return 1
  wt_root=$(wt root 2>/dev/null) || wt_root=
  repo_root=$(repo root 2>/dev/null) || repo_root=
  for row in ${(f)rows}; do
    f=("${(@ps:\t:)row}")
    dir=${f[4]-}
    shown=${dir/#$HOME/'~'}
    [[ -n $wt_root && $dir == "$wt_root"/* ]] && shown=${dir#"$wt_root"/}
    [[ -n $repo_root && $dir == "$repo_root"/* ]] && shown=${dir#"$repo_root"/}
    printf '[%s] %-24s %s\t%s\t%s\n' "$f[2]" "${f[3]-}" "$shown" "$f[1]" "$dir"
  done
}

# `<workspace id>\t<path>` of the workspace the popup was opened over. Read off
# `focused` because herdr 0.9.1 has no cwd for a workspace off a checkout.
_ui_focused_workspace() {
  local out
  out=$(herdr workspace list) || return 1
  print -r -- "$out" | jq -r '
    first(.result.workspaces[]? | select(.focused))
    | [.workspace_id, (.worktree.checkout_path // "")]
    | @tsv
  '
}
