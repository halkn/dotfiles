# wk - the one entry point for getting a repository, opening it, branching off
# it in a worktree, moving between what is open, and removing what is done. Each
# operation is a subcommand; the information each one works on lives in lib/.
#
# Inside a herdr session a choice becomes a workspace; outside it degrades to
# `cd`.
#
# This file is sourced from .zshrc and from ~/.config/herdr/*.sh, so it must
# only define functions and must not return early on a missing dependency: the
# picker would lose them silently.

_WK_LIB=${${(%):-%x}:A}

# lib/ holds only function definitions and nothing that reaches back here, so
# sourcing it twice is harmless and the load order does not matter. The herdr
# popups source this file alone and get the whole workflow with it.
for _wk_part in ui checkout forge session; do
  source "${${_WK_LIB:h}:h}/lib/$_wk_part.zsh"
done
unset _wk_part

# ── shared ───────────────────────────────────────────

_wk_in_repo() {
  git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
    print 'wk: not inside a git repository' >&2
    return 1
  }
}

_wk_confirm() {
  print -n "$1 [y/N] "
  if read -r -q; then
    print
    return 0
  fi
  print
  return 1
}

# mise prompts for trust on every new checkout path. Only code from a repository
# the user already works in gets pre-trusted.
_wk_trust_mise() {
  local wt_path=$1
  command -v mise >/dev/null 2>&1 || return 0
  [[ -f $wt_path/mise.toml || -f $wt_path/.mise.toml || -f $wt_path/mise/config.toml ]] || return 0
  mise trust --quiet "$wt_path" >/dev/null 2>&1 || true
}

# What Enter does differs per row, which is what the target column carries: a
# workspace is focused, anything else is a directory to open.
_wk_goto() {
  local target=${1:-}
  [[ -n $target ]] || return 1
  case $target in
    workspace:*)
      _sess_focus "${target#*:}"
      ;;
    *)
      _sess_open_worktree "$target"
      ;;
  esac
}

# ── go: bare `wk` ────────────────────────────────────

# Everything already open or already checked out, across every repository: the
# workspaces first, then the worktrees under $WT_ROOT. The two are not
# deduplicated - a worktree that is open appears as both - because the rows
# answer different questions and the workspace row is the one that carries the
# label.
_wk_go_rows() {
  _sess_workspace_rows
  _ck_wt_rows
}

_wk_go_pick() {
  local target
  _ui_require fzf wk || return 1
  target=$(
    _wk_go_rows \
      | fzf "${_UI_FZF_CHROME[@]}" \
        --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --prompt 'go> ' \
        --preview "source ${_UI_LIB}; _ui_git_preview {3}"
  )
  [[ -n $target ]] || return 1
  _wk_goto "$target"
}

# ── open: a repository or a place ────────────────────

# Where to start working, as opposed to where work is already going on. The
# repositories under $REPO_ROOT, plus the directories that are not repositories
# but are worked in anyway.
_wk_open_rows() {
  _ck_place_rows
  _ck_repo_rows
}

_wk_open_pick() {
  local dir
  _ui_require fzf wk || return 1
  dir=$(
    _wk_open_rows \
      | fzf "${_UI_FZF_CHROME[@]}" \
        --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --query "$*" \
        --prompt 'open> ' \
        --preview "source ${_UI_LIB}; _ui_git_preview {3}"
  )
  [[ -n $dir ]] || return 1
  _sess_open_dir "$dir"
}

# ── get: clone one in ────────────────────────────────

_wk_get_pick() {
  local spec out
  local -a repos
  _ui_require gh wk || return 1
  _ui_require fzf wk || return 1
  out=$(_forge_repo_list) || return 1
  repos=(${(f)out})
  ((${#repos})) || {
    print 'wk: gh listed no repositories' >&2
    return 1
  }
  spec=$(
    _forge_repo_rows "$(_ck_repo_root)" "${repos[@]}" \
      | fzf "${_UI_FZF_CHROME[@]}" \
        --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --prompt 'get> ' \
        --header '✓: already cloned' \
        --preview 'gh repo view {2}'
  )
  [[ -n $spec ]] || return 1
  print -r -- "$spec"
}

_wk_get() {
  local spec dest
  case $# in
    0)
      spec=$(_wk_get_pick) || return 1
      ;;
    1)
      spec=$1
      ;;
    *)
      print 'usage: wk get [<owner/repo|url>]' >&2
      return 1
      ;;
  esac
  dest=$(_ck_repo_dest "$spec") || return 1
  if [[ ! -d $dest ]]; then
    git clone "$(_forge_url "$spec")" "$dest" || return 1
  fi
  _sess_open_dir "$dest"
}

# ── new: a worktree for a branch ─────────────────────

# A branch is picked up where it already is - locally, then on origin - and only
# created when there is nothing to pick up, so a branch that exists only on the
# remote is tracked instead of being silently forked from the base.
_wk_new() {
  local branch=${1:-} base=${2:-} wt_path
  [[ -n $branch ]] || {
    print 'usage: wk new <branch> [base]' >&2
    return 1
  }
  wt_path=$(_ck_wt_path "$branch") || return 1

  if [[ -d $wt_path ]]; then
    _sess_open_worktree "$wt_path"
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

  _wk_trust_mise "$wt_path"
  _sess_open_worktree "$wt_path"
}

# ── pr: a worktree for a pull request ────────────────

_wk_pr_pick() {
  local rows
  _ui_require fzf wk || return 1
  # Fetched before the picker opens rather than from inside it, so a gh failure
  # is reported instead of showing an empty list.
  rows=$(_forge_pr_rows) || return 1
  [[ -n $rows ]] || {
    print 'wk: no open pull requests' >&2
    return 1
  }
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" \
      --delimiter '\t' --with-nth 1 --accept-nth 2 \
      --prompt 'pr> ' \
      --preview 'gh pr view {2}'
}

# The checkout itself is left to `gh pr checkout`, which is the only thing that
# gets a fork's head right (it fetches refs/pull/<n>/head and sets the push
# remote), so the worktree is added detached and gh is run inside it.
#
# The directory is named after the head branch, as `wk new` does. A fork's
# branch name is not qualified by its owner, so two pull requests proposing the
# same branch name collide the way two branches differing only in a `/` do.
_wk_pr() {
  local number=${1:-} branch wt_path
  _ui_require gh wk || return 1
  if [[ -z $number ]]; then
    number=$(_wk_pr_pick) || return 1
    [[ -n $number ]] || return 1
  fi
  number=${number#\#}

  branch=$(_forge_pr_head "$number") || return 1
  [[ -n $branch ]] || {
    print "wk: could not resolve the head branch of #$number" >&2
    return 1
  }

  wt_path=$(_ck_wt_path "$branch") || return 1
  if [[ -d $wt_path ]]; then
    _sess_open_worktree "$wt_path"
    return
  fi

  git worktree add --detach "$wt_path" HEAD >/dev/null || return 1
  if ! (cd -- "$wt_path" && gh pr checkout "$number"); then
    git worktree remove --force -- "$wt_path"
    return 1
  fi

  _wk_trust_mise "$wt_path"
  _sess_open_worktree "$wt_path"
}

# ── rm: remove a worktree ────────────────────────────

# Whether a worktree may go is git's own answer: it refuses one with local
# changes. Asking again with --force is the caller taking that decision.
#
# The one thing git does not refuse is the worktree the caller is standing in,
# which it removes out from under the shell, so that is refused here.
_wk_remove_path() {
  local wt_path=${1:A} root ws message rc
  if [[ ${PWD:A} == "$wt_path" || ${PWD:A} == "$wt_path"/* ]]; then
    print "wk: cannot remove the worktree you are standing in: $wt_path" >&2
    return 1
  fi
  ws=$(_sess_workspace_id "$wt_path")
  message=$(git worktree remove -- "$wt_path" 2>&1)
  rc=$?
  if ((rc != 0)); then
    print -r -- "$message" >&2
    _wk_confirm "remove ${wt_path:t} anyway?" || return 1
    git worktree remove --force -- "$wt_path" || return 1
  fi
  # Only inside the root lib/checkout.zsh lays out: elsewhere the parent belongs
  # to whoever put the worktree there. Resolved on both sides, since $wt_path is
  # and a root reached through a symlink would not compare otherwise.
  root=$(_ck_wt_root)
  [[ $wt_path == "${root:A}"/* ]] && rmdir -- "${wt_path:h}" 2>/dev/null
  _sess_close_worktree "$ws"
  return 0
}

_wk_rm() {
  local rows line tmp wt_path
  local -a targets
  _ui_require fzf wk || return 1

  rows=$(_ck_wt_repo_rows)
  [[ -n $rows ]] || {
    print 'wk: no worktrees' >&2
    return 0
  }

  # Buffer through a temp file: a picker inside <(...) is not in the foreground
  # process group, so it blocks on /dev/tty (SIGTTIN) and wk hangs.
  tmp=$(mktemp "${TMPDIR:-/tmp}/wk-rm.XXXXXX") || return 1
  print -r -- "$rows" \
    | fzf "${_UI_FZF_CHROME[@]}" \
      --multi --delimiter '\t' --with-nth 1 --accept-nth 2 \
      --prompt 'remove> ' \
      --header 'Tab: toggle / Enter: remove selected' \
      --preview "source ${_UI_LIB}; _ui_git_preview {3}" >|"$tmp"

  while IFS= read -r line; do
    [[ -n $line ]] || continue
    targets+=("$line")
  done <"$tmp"
  rm -f -- "$tmp"
  ((${#targets} == 0)) && return 0

  print -r -- "${(F)targets}"
  _wk_confirm 'remove these worktrees?' || return 1
  for wt_path in "${targets[@]}"; do
    _wk_remove_path "$wt_path"
  done
}

# ── command ──────────────────────────────────────────

# wk                        : go to a workspace or a worktree
# wk open [<query>...]      : open a repository or a place as a workspace
# wk get [<owner/repo|url>] : clone one in and open it
# wk new <branch> [base]    : create the worktree for a branch and open it
# wk pr [<number>]          : create the worktree for a pull request and open it
# wk rm                     : pick worktrees of this repository to remove
#
# The bare form and `open` span every repository; `new`, `pr` and `rm` act on
# the one you are standing in.
wk() {
  case ${1:-} in
    '')
      _wk_go_pick
      ;;
    open)
      shift
      _wk_open_pick "$@"
      ;;
    get)
      shift
      _wk_get "$@"
      ;;
    new)
      shift
      _wk_in_repo || return 1
      _wk_new "$@"
      ;;
    pr)
      shift
      _wk_in_repo || return 1
      _wk_pr "$@"
      ;;
    rm)
      shift
      _wk_in_repo || return 1
      _wk_rm
      ;;
    -h | --help | help)
      print 'usage: wk [open [<query>...] | get [<owner/repo|url>] | new <branch> [base] | pr [<number>] | rm]'
      ;;
    *)
      print "wk: unknown subcommand: $1" >&2
      return 1
      ;;
  esac
}
