# ws - where to start working: a repository under $REPO_ROOT, or one of the
# directories that are not repositories but are worked in anyway. Inside herdr
# the choice becomes a new workspace; outside it degrades to `cd`.
#
# Going to a place that is already open is wt's ($WT_ROOT and the open
# workspaces); this one only opens.
#
# This file is sourced from .zshrc and from ~/.config/herdr/herdr-open.sh, so it
# must only define functions and must not return early on a missing dependency.

_WS_LIB=${${(%):-%x}:A}

# Full screen with the preview under the list: this also runs as a herdr popup,
# which is too narrow for a preview beside the list. FZF_DEFAULT_OPTS is sized
# for a completion popped up under the cursor, which is not what this is.
typeset -ga _WS_FZF_CHROME=(
  --height=100%
  --style=full
  --border-label=' ws '
  --preview-window 'down:60%:wrap'
)

# ── listing ──────────────────────────────────────────
# Rows are `<display>\t<path>`.

# $WS_PLACES holds the directories that are not repositories ($HOME and the temp
# dir by default, set in .zshenv, extended per machine in .zshenv.local). The
# listing is shared by every machine, so a path this one does not have is
# dropped instead of offered as a row that cannot be opened.
_ws_place_rows() {
  local dir
  # The default is for the `set -u` the herdr popup runs with: an unset variable
  # would otherwise end the listing.
  for dir in ${(s.:.)${WS_PLACES:-}}; do
    # A `~` written by hand is expanded the way repo.zsh expands $REPO_ROOT:
    # unexpanded, it would be dropped below as a path this machine does not
    # have, which is indistinguishable from the drop that is meant.
    dir=${dir/#\~/$HOME}
    [[ -d $dir ]] || continue
    printf 'dir  %s\t%s\n' "${dir/#$HOME/~}" "${dir:A}"
  done
  return 0
}

# The repositories are repo.zsh's listing. Workflow files do not source each
# other, so a caller that loads only this one - the herdr popup - gets the
# places and no repositories rather than an error.
_ws_rows() {
  _ws_place_rows
  whence _repo_rows >/dev/null 2>&1 && _repo_rows
  return 0
}

# ── preview ──────────────────────────────────────────

# Runs in a fresh shell that sources this file alone, so it cannot reach
# repo.zsh's preview - and a place is not a repository anyway.
_ws_preview() {
  local dir=${1:-}
  [[ -d $dir ]] || return 0
  print -r -- "$dir"
  print
  if git -C "$dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$dir" -c color.ui=always status --short --branch 2>/dev/null
    print
    git -C "$dir" log --oneline --decorate --color=always -15 2>/dev/null
  else
    ls -A -- "$dir" 2>/dev/null | head -30
  fi
  return 0
}

# ── opening ──────────────────────────────────────────

_ws_open_dir() {
  local dir=${1:A}
  [[ -d $dir ]] || {
    print "ws: no such directory: $dir" >&2
    return 1
  }
  # The herdr workspace API is served over the session socket, so it only
  # answers from inside a session.
  if [[ -n ${HERDR_ENV:-} ]] && command -v herdr >/dev/null 2>&1; then
    herdr workspace create --cwd "$dir" --focus >/dev/null 2>&1 && return 0
    print 'ws: herdr could not create the workspace; falling back to cd' >&2
  fi
  cd -- "$dir"
}

_ws_pick() {
  local dir
  command -v fzf >/dev/null 2>&1 || {
    print 'ws: fzf is not installed' >&2
    return 1
  }
  dir=$(
    _ws_rows \
      | fzf "${_WS_FZF_CHROME[@]}" \
        --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --query "$*" \
        --prompt 'open> ' \
        --preview "source ${_WS_LIB}; _ws_preview {2}"
  )
  [[ -n $dir ]] || return 1
  _ws_open_dir "$dir"
}

# ws [<query>...] : pick a repository or a place and open a workspace on it
ws() {
  case ${1:-} in
    -h | --help | help)
      print 'usage: ws [<query>...]'
      ;;
    *)
      _ws_pick "$@"
      ;;
  esac
}
