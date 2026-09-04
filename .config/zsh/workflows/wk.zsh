# wk - the one entry point for getting a repository, opening it, branching off
# it in a worktree, moving between what is open, and removing what is done.
# Inside a herdr session a choice becomes a workspace; outside it degrades to
# `cd`.
#
# Sourced from .zshrc and from ~/.config/herdr/*.sh, so it must only define
# functions and must not return early on a missing dependency: a herdr popup
# would lose them silently.

_WK_LIB=${${(%):-%x}:A}

# Sourced by absolute path so that a herdr popup gets the whole workflow from
# this file alone. lib/ never reaches back here, so the order does not matter.
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

# The repository comes first so that sorting on the display column groups the
# rows of one repository together, whichever layer they came from.
_wk_go_row() {
  printf '%-24s %-24s %s\t%s\t%s\n' "$1" "$2" "$3" "$4" "$5"
}

# herdr's workspaces, then the worktrees none of them is on. An open worktree is
# one row, not two, since both would land in the same workspace anyway and the
# workspace row also carries herdr's number and label. Both kinds are named
# through _ck_describe so that one listing reads one way. Sorted in C order so
# the grouping does not depend on the locale the picker happens to run in.
_wk_go_rows() {
  local workspaces
  # Read before the block below: a pipeline would put the loop in a subshell and
  # lose the paths collected while laying out the workspace rows.
  workspaces=$(_sess_workspace_rows)
  {
    local line id number label wt_path repo branch
    local -A open
    local -a fields
    # Split rather than `read`: a tab is IFS whitespace in zsh, so an empty
    # field would be folded away and shift every column after it.
    for line in ${(f)workspaces}; do
      fields=("${(@ps:\t:)line}")
      id=${fields[1]-}
      [[ -n $id ]] || continue
      number=${fields[2]-}
      label=${fields[3]-}
      wt_path=${fields[4]-}
      if [[ -n $wt_path ]]; then
        open[${wt_path:A}]=1
      fi
      IFS=$'\t' read -r repo branch <<<"$(_ck_describe "$wt_path")"
      if [[ -n $repo ]]; then
        _wk_go_row "$repo" "$branch" "ws [$number] $label" "workspace:$id" "$wt_path"
      else
        # herdr's label takes the place of the repository, so the column the
        # rows are ordered on is never empty.
        _wk_go_row "$label" '' "ws [$number]" "workspace:$id" "$wt_path"
      fi
    done
    for wt_path in ${(f)"$(_ck_wt_paths)"}; do
      # An empty listing reads back as one empty field.
      [[ -n $wt_path ]] || continue
      if [[ -n ${open[${wt_path:A}]-} ]]; then
        continue
      fi
      IFS=$'\t' read -r repo branch <<<"$(_ck_describe "$wt_path")"
      _wk_go_row "$repo" "$branch" 'wt' "$wt_path" "$wt_path"
    done
  } | LC_ALL=C sort -t$'\t' -k1,1
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

# Where to start working, as opposed to where work is already going on.
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

# With no base, a branch is picked up where it already is - locally, then on
# origin - so one that exists only on the remote is tracked instead of silently
# forked. A base always means a new branch, and fails if it already exists.
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

# `gh pr checkout` is the only thing that gets a fork's head right, so the
# worktree is added detached and gh is run inside it. The directory is named
# after the head branch, which a fork does not qualify by owner: two pull
# requests proposing the same branch name collide.
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

# Whether a worktree may go is git's answer; --force is the caller taking that
# decision. The one thing git does not refuse is the worktree the caller stands
# in, which it removes out from under the shell, so that is refused here.
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
  # Only inside $WT_ROOT: elsewhere the parent belongs to whoever created it.
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
