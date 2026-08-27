# wt - one worktree per branch, all of them under one root, and a picker to go
# to any of them. Inside a herdr session a checkout is opened as a workspace;
# outside it degrades to `cd`.
#
# This file is sourced from .zshrc and from ~/.config/herdr/herdr-picker.sh, so
# it must only define functions and must not return early on a missing
# dependency: the picker would lose them silently.

_WT_LIB=${${(%):-%x}:A}

# All worktrees live at <root>/<owner>/<repo>/<branch-slug>, which is what lets
# the listing be a glob instead of a git call per repository.
_wt_root() {
  local root=${WT_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/worktrees}
  print -r -- "${root%/}"
}

_wt_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print 'wt: not inside a git repository' >&2
    return 1
  }
}

_wt_fzf_available() {
  command -v fzf >/dev/null 2>&1 || {
    print "${1:-wt}: fzf is not installed" >&2
    return 1
  }
}

# The herdr workspace API is served over the session socket, so it only answers
# from inside a session. The default keeps this usable from the herdr picker,
# which runs under `set -u`.
_wt_use_herdr() {
  [[ -n ${HERDR_ENV:-} ]] && command -v herdr >/dev/null 2>&1
}

# A branch name is a path segment here, so `/` is folded away. Two branches that
# differ only in that separator would share a directory; the collision is
# accepted rather than encoded.
_wt_slug() {
  print -r -- "${1//\//-}"
}

# <owner>/<repo> read off the main checkout's own path rather than off the
# remote URL, so a repository with no remote, or one placed outside $REPO_ROOT,
# still lands somewhere predictable.
_wt_repo_slug() {
  local common main
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  main=${common:h}
  print -r -- "${${main:h}:t}/${main:t}"
}

# mise prompts for trust on every new checkout path. Only code from a repository
# the user already works in gets pre-trusted.
_wt_trust_mise() {
  local wt_path=$1
  command -v mise >/dev/null 2>&1 || return 0
  [[ -f $wt_path/mise.toml || -f $wt_path/.mise.toml || -f $wt_path/mise/config.toml ]] || return 0
  mise trust --quiet "$wt_path" >/dev/null 2>&1 || true
}

# ── listing ──────────────────────────────────────────
# Rows are `<display>\t<kind>:<target>\t<path>`. The kind decides what Enter
# does, which differs per row: a workspace is focused, a checkout is opened.

# Every open herdr workspace. Empty outside a session, and empty rather than
# failing when the server does not answer: the herdr picker runs the listing
# under `set -euo pipefail`.
_wt_workspace_rows() {
  local workspaces
  _wt_use_herdr || return 0
  command -v jq >/dev/null 2>&1 || return 0
  workspaces=$(herdr workspace list 2>/dev/null) || return 0
  [[ -n $workspaces ]] || return 0
  print -r -- "$workspaces" | jq -r '
    .result.workspaces[]?
    | ["ws   [\(.number)] \(.label)",
       "workspace:\(.workspace_id)",
       (.worktree.checkout_path // "")]
    | @tsv
  ' 2>/dev/null
  return 0
}

_wt_checkout_rows() {
  local wt_path root
  root=$(_wt_root)
  for wt_path in "$root"/*/*/*(N/); do
    printf 'wt   %-30s %s\tworktree:%s\t%s\n' \
      "${${wt_path:h:h}:t}/${wt_path:h:t}" "${wt_path:t}" "$wt_path" "$wt_path"
  done
  return 0
}

_wt_rows() {
  _wt_workspace_rows
  _wt_checkout_rows
}

# ── preview ──────────────────────────────────────────

_wt_preview() {
  local entry=${1:-} wt_path=${2:-}
  if [[ ${entry%%:*} == workspace && -z $wt_path ]]; then
    print -r -- "${entry#*:}"
    return 0
  fi
  wt_path=${wt_path:A}
  print -r -- "$wt_path"
  [[ -d $wt_path ]] || {
    print 'missing'
    return 0
  }
  print
  git -C "$wt_path" -c color.ui=always status --short --branch 2>/dev/null
  print
  git -C "$wt_path" log --oneline --decorate --color=always -15 2>/dev/null
  # A directory git refuses must not end the preview process, which runs under
  # `set -e` in the herdr picker.
  return 0
}

# ── going there ──────────────────────────────────────

# open_workspace_id of the checkout at $1, empty when it is not open in herdr.
_wt_workspace_id() {
  local wt_path=$1
  _wt_use_herdr || return 0
  command -v jq >/dev/null 2>&1 || return 0
  herdr worktree list --json 2>/dev/null \
    | jq -r --arg p "$wt_path" \
      '.result.worktrees[]? | select(.path == $p) | .open_workspace_id // empty' 2>/dev/null
  return 0
}

_wt_open_path() {
  local wt_path=${1:A} ws
  [[ -d $wt_path ]] || {
    print "wt: no such worktree: $wt_path" >&2
    return 1
  }
  if _wt_use_herdr; then
    ws=$(_wt_workspace_id "$wt_path")
    if [[ -n $ws ]]; then
      herdr workspace focus "$ws" >/dev/null && return 0
    elif herdr worktree open --path "$wt_path" --focus >/dev/null 2>&1; then
      return 0
    fi
    print 'wt: herdr could not open the worktree; falling back to cd' >&2
  fi
  cd -- "$wt_path"
}

_wt_open() {
  local entry=${1:-}
  [[ -n $entry ]] || return 1
  case ${entry%%:*} in
    workspace)
      _wt_use_herdr || {
        print 'wt: workspaces can only be focused inside herdr' >&2
        return 1
      }
      herdr workspace focus "${entry#*:}" >/dev/null
      ;;
    worktree)
      _wt_open_path "${entry#*:}"
      ;;
    *)
      return 1
      ;;
  esac
}

# Pick a place and go there. $1 names the calling command so its guard message
# reads as that command; the rest is fzf chrome, which is the only thing `wt`
# and the herdr popup do not share.
_wt_pick() {
  local name=${1:-wt} entry
  if (($# > 0)); then
    shift
  fi
  _wt_fzf_available "$name" || return 1
  entry=$(
    _wt_rows \
      | fzf --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --prompt 'go> ' \
        --preview "source ${_WT_LIB}; _wt_preview {2} {3}" \
        "$@"
  )
  [[ -n $entry ]] || return 1
  _wt_open "$entry"
}

# ── creating ─────────────────────────────────────────

# Create the worktree for a branch and open it. A branch is picked up where it
# already is - locally, then on origin - and only created when there is nothing
# to pick up, so a branch that exists only on the remote is tracked instead of
# being silently forked from the base.
_wt_new() {
  local branch=${1:-} base=${2:-} wt_path slug
  [[ -n $branch ]] || {
    print 'usage: wt new <branch> [base]' >&2
    return 1
  }
  slug=$(_wt_repo_slug) || return 1
  wt_path=$(_wt_root)/$slug/$(_wt_slug "$branch")

  if [[ -d $wt_path ]]; then
    _wt_open_path "$wt_path"
    return
  fi

  if [[ -n $base ]]; then
    git worktree add -b "$branch" "$wt_path" "$base" || return 1
  elif git show-ref --verify --quiet "refs/heads/$branch"; then
    git worktree add "$wt_path" "$branch" || return 1
  elif git fetch origin "$branch" 2>/dev/null &&
    git show-ref --verify --quiet "refs/remotes/origin/$branch"; then
    git worktree add --track -b "$branch" "$wt_path" "origin/$branch" || return 1
  else
    git worktree add -b "$branch" "$wt_path" || return 1
  fi

  _wt_trust_mise "$wt_path"
  _wt_open_path "$wt_path"
}

# ── removing ─────────────────────────────────────────

# `git worktree list --porcelain` on stdin, main checkout excluded: git puts it
# first. Kept apart from the call below so a test can pin the columns down.
_wt_repo_rows_filter() {
  awk '
    function flush() {
      if (wt == "") return
      if (++n > 1) printf "%-40s %s\t%s\n", br, wt, wt
      wt = ""; br = ""
    }
    /^worktree / { flush(); wt = substr($0, 10); next }
    /^branch /   { br = substr($0, 8); sub(/^refs\/heads\//, "", br); next }
    /^detached$/ { br = "(detached)"; next }
    END          { flush() }
  '
}

# The worktrees of this repository.
_wt_repo_rows() {
  git worktree list --porcelain 2>/dev/null | _wt_repo_rows_filter
}

_wt_confirm() {
  print -n "$1 [y/N] "
  if read -r -q; then
    print
    return 0
  fi
  print
  return 1
}

# Whether a worktree may go is git's own answer: it refuses one with local
# changes. Asking again with --force is the caller taking that decision.
_wt_remove_path() {
  local wt_path=${1:A} ws message rc
  ws=$(_wt_workspace_id "$wt_path")
  message=$(git worktree remove -- "$wt_path" 2>&1)
  rc=$?
  if ((rc != 0)); then
    print -r -- "$message" >&2
    _wt_confirm "remove ${wt_path:t} anyway?" || return 1
    git worktree remove --force -- "$wt_path" || return 1
  fi
  rmdir -- "${wt_path:h}" 2>/dev/null || true
  if [[ -n $ws ]]; then
    herdr workspace close "$ws" >/dev/null 2>&1 || true
  fi
  return 0
}

_wt_rm() {
  local rows line tmp wt_path
  local -a targets
  _wt_fzf_available || return 1

  rows=$(_wt_repo_rows)
  [[ -n $rows ]] || {
    print 'wt: no worktrees' >&2
    return 0
  }

  # Buffer through a temp file: a picker inside <(...) is not in the foreground
  # process group, so it blocks on /dev/tty (SIGTTIN) and wt hangs.
  tmp=$(mktemp "${TMPDIR:-/tmp}/wt-rm.XXXXXX") || return 1
  print -r -- "$rows" \
    | fzf --multi --delimiter '\t' --with-nth 1 --accept-nth 2 \
      --prompt 'remove> ' \
      --header 'Tab: toggle / Enter: remove selected' \
      --preview "source ${_WT_LIB}; _wt_preview worktree:{2} {2}" >|"$tmp"

  while IFS= read -r line; do
    [[ -n $line ]] || continue
    targets+=("$line")
  done <"$tmp"
  rm -f -- "$tmp"
  ((${#targets} == 0)) && return 0

  print -r -- "${(F)targets}"
  _wt_confirm 'remove these worktrees?' || return 1
  for wt_path in "${targets[@]}"; do
    _wt_remove_path "$wt_path"
  done
}

# ── command ──────────────────────────────────────────

# wt                     : pick a workspace or worktree and go there
# wt new <branch> [base] : create the worktree for a branch and open it
# wt rm                  : pick worktrees of this repository to remove
#
# The bare form spans every repository; the subcommands act on the one you are
# standing in.
wt() {
  case ${1:-} in
    '')
      _wt_pick wt
      ;;
    new)
      shift
      _wt_in_repo || return 1
      _wt_new "$@"
      ;;
    rm)
      shift
      _wt_in_repo || return 1
      _wt_rm
      ;;
    -h | --help | help)
      print 'usage: wt [new <branch> [base] | rm]'
      ;;
    *)
      print "wt: unknown subcommand: $1" >&2
      return 1
      ;;
  esac
}
