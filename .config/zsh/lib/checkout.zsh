# checkout - where a checkout lives on this machine: `$REPO_ROOT/<host>/<...>/<repo>`
# for the clones, `$WT_ROOT/<owner>/<repo>/<branch>` for the worktrees.
#
# The layout is the listing. Rows come from a glob over the root so that no git
# process is spawned per row; git is asked at the preview and at the moment of
# acting. A row is `<display>\t<target>\t<path>`: the target is what Enter acts
# on, the path is what the preview reads, and they differ for a row that is not
# a directory of its own. _ck_wt_paths is the exception - it serves bare paths,
# because its caller interleaves them with herdr's rows and names both itself.

# ── clones ───────────────────────────────────────────

_ck_repo_root() {
  local root=${REPO_ROOT:-$HOME/repos}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

_ck_repo_dest() {
  local spec=${1:-} rest
  [[ -n $spec ]] || return 1
  case $spec in
    *:* | *@* | */*/*) ;;
    */*)
      print -r -- "$(_ck_repo_root)/github.com/$spec"
      return 0
      ;;
  esac
  rest=${spec#*://}
  rest=${rest#*@}
  rest=${rest/:/\/}
  rest=${rest%.git}
  rest=${rest/\/_git\//\/}
  print -r -- "$(_ck_repo_root)/${rest%/}"
}

# The second glob is the <host>/<org>/<project>/<repo> depth Azure DevOps needs.
_ck_repo_rows() {
  local dir root
  root=$(_ck_repo_root)
  for dir in "$root"/*/*/*(N/) "$root"/*/*/*/*(N/); do
    [[ -e $dir/.git ]] || continue
    printf 'repo %s\t%s\t%s\n' "${dir#"$root"/}" "$dir" "$dir"
  done
  return 0
}

# ── places ───────────────────────────────────────────

# $WS_PLACES is shared by every machine, so a path this one does not have is
# dropped rather than offered as a row that cannot be opened. The default value
# is for the `set -u` the herdr popup runs with.
_ck_place_rows() {
  local dir
  for dir in ${(s.:.)${WS_PLACES:-}}; do
    # Expanded here, or a hand-written `~` would be dropped as a missing path.
    dir=${dir/#\~/$HOME}
    [[ -d $dir ]] || continue
    printf 'dir  %s\t%s\t%s\n' "${dir/#$HOME/~}" "${dir:A}" "${dir:A}"
  done
  return 0
}

# ── worktrees ────────────────────────────────────────

# The default matches herdr's own `[worktrees] directory`; change both together.
_ck_wt_root() {
  local root=${WT_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/worktrees}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

# A branch name is a path segment here. Two branches differing only in `/` share
# a directory; the collision is accepted rather than encoded.
_ck_wt_slug() {
  print -r -- "${1//\//-}"
}

# Read off the main checkout's path rather than the remote URL, so a repository
# with no remote still lands somewhere predictable.
_ck_wt_repo_slug() {
  local common main
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  main=${common:h}
  print -r -- "${${main:h}:t}/${main:t}"
}

_ck_wt_path() {
  local branch=${1:-} slug
  [[ -n $branch ]] || return 1
  slug=$(_ck_wt_repo_slug) || return 1
  print -r -- "$(_ck_wt_root)/$slug/$(_ck_wt_slug "$branch")"
}

_ck_wt_paths() {
  local wt_path root
  root=$(_ck_wt_root)
  for wt_path in "$root"/*/*/*(N/); do
    print -r -- "$wt_path"
  done
  return 0
}

# ── labels ───────────────────────────────────────────

# `<repo>\t<branch>` for a checkout path, read off the layout alone so that a
# listing still costs no git process per row. A branch reads back with `-` where
# _ck_wt_slug folded a `/` out. Both roots and the path are resolved before they
# are compared: a root reached through a symlink is spelled one way in $WT_ROOT
# and another in what git and herdr report.
_ck_describe() {
  local dir=${1:-} root
  local -a parts
  [[ -n $dir ]] || return 0
  dir=${${dir%/}:A}

  root=${${:-$(_ck_wt_root)}:A}
  if [[ $dir == "$root"/* ]]; then
    parts=(${(s:/:)${dir#"$root"/}})
    if ((${#parts} == 3)); then
      printf '%s/%s\t%s\n' "$parts[1]" "$parts[2]" "$parts[3]"
      return 0
    fi
  fi

  # Unlike the worktree layout above, the depth does not say where a checkout
  # ends - a directory inside one has the same shape - so .git is what does.
  root=${${:-$(_ck_repo_root)}:A}
  if [[ $dir == "$root"/* && -e $dir/.git ]]; then
    parts=(${(s:/:)${dir#"$root"/}})
    if ((${#parts} == 3 || ${#parts} == 4)); then
      printf '%s/%s\t\n' "$parts[-2]" "$parts[-1]"
      return 0
    fi
  fi

  printf '%s\t\n' "${dir/#$HOME/~}"
}

# `git worktree list --porcelain` on stdin. Three rows are withheld because git
# removes all three without complaint and each costs something unrecoverable:
# the main checkout (listed first), the worktree $1 stands in (the shell would
# be left in a directory that is gone), and anything under .claude/worktrees
# (Claude Code's lifecycle; an agent may still be running in it).
_ck_wt_repo_rows_filter() {
  awk -v cwd="${1:-}" '
    function keep(p) {
      if (p == cwd || index(cwd, p "/") == 1) return 0
      if (index(p, "/.claude/worktrees/") > 0) return 0
      return 1
    }
    function flush() {
      if (wt == "") return
      if (++n > 1 && keep(wt)) printf "%-40s %s\t%s\t%s\n", br, wt, wt, wt
      wt = ""; br = ""
    }
    /^worktree / { flush(); wt = substr($0, 10); next }
    /^branch /   { br = substr($0, 8); sub(/^refs\/heads\//, "", br); next }
    /^detached$/ { br = "(detached)"; next }
    END          { flush() }
  '
}

# git reports resolved paths, so $PWD is resolved too or the two would not compare.
_ck_wt_repo_rows() {
  git worktree list --porcelain 2>/dev/null | _ck_wt_repo_rows_filter "${PWD:A}"
}
