# checkout - where a checkout lives on this machine. Two roots, one layout
# each: `$REPO_ROOT/<host>/<...>/<repo>` for the clones and
# `$WT_ROOT/<owner>/<repo>/<branch>` for the worktrees.
#
# The layout is the listing: a glob over the root, so no git process is spawned
# per row. git is asked at the preview and at the moment of acting, not to build
# a list.
#
# A row here is `<display>\t<target>\t<path>`, the shape the pickers in
# workflows/ consume. The target is what Enter acts on and the path is what the
# preview reads; they differ only for a row that is not a directory of its own,
# which is why the column is kept separate.
#
# A listing whose rows are interleaved with another layer's - the worktrees,
# which the pickers show next to herdr's workspaces - is served as bare paths
# plus _ck_describe instead, so that the one caller that sees both lays both out
# the same way.

# ── clones ───────────────────────────────────────────

_ck_repo_root() {
  local root=${REPO_ROOT:-$HOME/repos}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

# Where a clone lands: <root>/<host>/<path>. `owner/repo` is taken as GitHub;
# anything else is read as a clone URL, with the scheme, the ssh user, the `:`
# separator, Azure's `_git/` segment and the `.git` suffix taken off.
_ck_repo_dest() {
  local spec=${1:-} rest
  [[ -n $spec ]] || return 1
  # `owner/repo` is the only form that is not a URL, so anything carrying a
  # host - a scheme, an ssh user, a `:` - is read as one.
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

# Two depths: <host>/<owner>/<repo>, and the <host>/<org>/<project>/<repo> that
# Azure DevOps needs.
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

# $WS_PLACES holds the directories that are not repositories ($HOME and the temp
# dir by default, set in .zshenv, extended per machine in .zshenv.local). The
# listing is shared by every machine, so a path this one does not have is
# dropped instead of offered as a row that cannot be opened.
_ck_place_rows() {
  local dir
  # The default is for the `set -u` the herdr popup runs with: an unset variable
  # would otherwise end the listing.
  for dir in ${(s.:.)${WS_PLACES:-}}; do
    # A `~` written by hand is expanded the way $REPO_ROOT is: unexpanded, it
    # would be dropped below as a path this machine does not have, which is
    # indistinguishable from the drop that is meant.
    dir=${dir/#\~/$HOME}
    [[ -d $dir ]] || continue
    printf 'dir  %s\t%s\t%s\n' "${dir/#$HOME/~}" "${dir:A}" "${dir:A}"
  done
  return 0
}

# ── worktrees ────────────────────────────────────────

# The default is herdr's own `[worktrees] directory`, so a worktree herdr
# creates and one `wk new` creates land in the same tree and appear in the same
# listing.
_ck_wt_root() {
  local root=${WT_ROOT:-${XDG_DATA_HOME:-$HOME/.local/share}/worktrees}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

# A branch name is a path segment here, so `/` is folded away. Two branches that
# differ only in that separator would share a directory; the collision is
# accepted rather than encoded.
_ck_wt_slug() {
  print -r -- "${1//\//-}"
}

# <owner>/<repo> read off the main checkout's own path rather than off the
# remote URL, so a repository with no remote, or one placed outside $REPO_ROOT,
# still lands somewhere predictable.
_ck_wt_repo_slug() {
  local common main
  common=$(git rev-parse --path-format=absolute --git-common-dir 2>/dev/null) || return 1
  main=${common:h}
  print -r -- "${${main:h}:t}/${main:t}"
}

# Where the worktree of $1 (a branch) in the repository the caller stands in
# goes.
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

# `<repo>\t<branch>` for a checkout path: what a picker row is named and sorted
# by. Read off the layout alone, so a listing still costs no git process per
# row. Only $WT_ROOT spells a branch out; a clone answers with the repository
# and an empty branch, and a path under neither root is named by itself.
#
# The branch of a worktree is the directory name, which _ck_wt_slug folded `/`
# out of, so a nested branch reads back with `-` where it was created with `/`.
# Both roots and the path are resolved before they are compared: a root reached
# through a symlink is spelled one way in $WT_ROOT and another in what git and
# herdr report, and the two would not match.
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

  # <host>/<owner>/<repo>, and the <host>/<org>/<project>/<repo> that Azure
  # DevOps needs: the repository is the last two segments either way. Unlike the
  # worktree layout above, the depth does not say where the checkout ends - a
  # directory inside one has the same shape - so the .git the clone itself
  # carries is what does.
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

# `git worktree list --porcelain` on stdin, laid out for the removal picker.
# Three kinds of row are withheld, because `git worktree remove` takes all three
# without complaint and each one costs something that cannot be undone by hand:
#
#   - the main checkout, which git lists first
#   - the worktree $1 is standing in: removing it leaves the shell in a
#     directory that no longer exists
#   - anything under .claude/worktrees, whose lifecycle is Claude Code's and
#     which may still have an agent running in it
#
# Kept apart from the call below so a test can pin the columns and the
# exclusions down.
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

# The worktrees of the repository the caller stands in. git reports resolved
# paths, so the working directory is resolved too or the two spellings would not
# compare.
_ck_wt_repo_rows() {
  git worktree list --porcelain 2>/dev/null | _ck_wt_repo_rows_filter "${PWD:A}"
}
