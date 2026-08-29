# session - the herdr side: what is open, and how a directory becomes a place to
# work in. This is the only file that runs `herdr`, so the boundary between what
# only a shell can do (`cd`) and what an external command does is a file
# boundary.
#
# Everything here degrades: outside a herdr session, or on a machine without it,
# the caller still gets a working `cd`.

# The workspace API is served over the session socket, so it only answers from
# inside a session. The default is for the `set -u` the herdr picker runs with.
_sess_available() {
  [[ -n ${HERDR_ENV:-} ]] && command -v herdr >/dev/null 2>&1
}

# `<workspace_id>\t<number>\t<label>\t<checkout_path>` for every open workspace.
# What the picker shows is left to the caller: a workspace row is laid out next
# to checkout.zsh's worktree rows, and only the caller sees both.
#
# A field may be empty: a workspace does not have to sit on a checkout, and
# herdr does not have to have labelled it. The caller splits on the tab itself
# rather than with `read`, which folds two adjacent tabs into one.
#
# Empty outside a session, and empty rather than failing when the server does
# not answer: the herdr picker runs the listing under `set -euo pipefail`.
_sess_workspace_rows() {
  local workspaces
  _sess_available || return 0
  command -v jq >/dev/null 2>&1 || return 0
  workspaces=$(herdr workspace list 2>/dev/null) || return 0
  [[ -n $workspaces ]] || return 0
  print -r -- "$workspaces" | jq -r '
    .result.workspaces[]?
    | [.workspace_id,
       (.number | tostring),
       .label,
       (.worktree.checkout_path // "")]
    | @tsv
  ' 2>/dev/null
  return 0
}

# open_workspace_id of the checkout at $1, empty when it is not open in herdr.
_sess_workspace_id() {
  local wt_path=$1 worktrees
  _sess_available || return 0
  command -v jq >/dev/null 2>&1 || return 0
  worktrees=$(herdr worktree list --json 2>/dev/null) || return 0
  [[ -n $worktrees ]] || return 0
  print -r -- "$worktrees" \
    | jq -r --arg p "$wt_path" \
      '.result.worktrees[]? | select(.path == $p) | .open_workspace_id // empty' 2>/dev/null
  return 0
}

_sess_focus() {
  local ws=${1:-}
  _sess_available || {
    print 'wk: workspaces can only be focused inside herdr' >&2
    return 1
  }
  herdr workspace focus "$ws" >/dev/null
}

# A directory that is not a checkout of its own: a new workspace is created on
# it every time, since there is nothing to reopen.
_sess_open_dir() {
  local dir=${1:A}
  [[ -d $dir ]] || {
    print "wk: no such directory: $dir" >&2
    return 1
  }
  if _sess_available; then
    herdr workspace create --cwd "$dir" --focus >/dev/null 2>&1 && return 0
    print 'wk: herdr could not create the workspace; falling back to cd' >&2
  fi
  cd -- "$dir"
}

# A worktree: the workspace it is already open in is focused rather than opened
# a second time.
_sess_open_worktree() {
  local wt_path=${1:A} ws
  [[ -d $wt_path ]] || {
    print "wk: no such worktree: $wt_path" >&2
    return 1
  }
  if _sess_available; then
    ws=$(_sess_workspace_id "$wt_path")
    if [[ -n $ws ]]; then
      herdr workspace focus "$ws" >/dev/null && return 0
    elif herdr worktree open --path "$wt_path" --focus >/dev/null 2>&1; then
      return 0
    fi
    print 'wk: herdr could not open the worktree; falling back to cd' >&2
  fi
  cd -- "$wt_path"
}

# Called after the checkout is gone. Failure is ignored: the removal already
# happened, and a workspace herdr no longer knows about is not an error worth
# reporting to someone who just removed a worktree.
_sess_close_worktree() {
  local ws=${1:-}
  [[ -n $ws ]] || return 0
  _sess_available || return 0
  herdr workspace close "$ws" >/dev/null 2>&1 || true
  return 0
}
