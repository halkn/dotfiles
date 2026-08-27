# repo - the repositories under one root: pick one to go to, or clone one in.
# Worktrees are wt's, and live under their own root; this listing is only the
# main checkouts.
#
# This file is sourced from .zshrc, so it must only define functions and must
# not return early on a missing dependency.

# Own path, so the fzf preview (which runs in a fresh shell) can re-source it.
_REPO_LIB=${${(%):-%x}:A}

_repo_root() {
  local root=${REPO_ROOT:-$HOME/repos}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

# Where a clone lands: <root>/<host>/<path>. `owner/repo` is taken as GitHub;
# anything else is read as a clone URL, with the scheme, the ssh user, the `:`
# separator, Azure's `_git/` segment and the `.git` suffix taken off.
_repo_dest() {
  local spec=${1:-} rest
  [[ -n $spec ]] || return 1
  # `owner/repo` is the only form that is not a URL, so anything carrying a
  # host - a scheme, an ssh user, a `:` - is read as one.
  case $spec in
    *:* | *@* | */*/*) ;;
    */*)
      print -r -- "$(_repo_root)/github.com/$spec"
      return 0
      ;;
  esac
  rest=${spec#*://}
  rest=${rest#*@}
  rest=${rest/:/\/}
  rest=${rest%.git}
  rest=${rest/\/_git\//\/}
  print -r -- "$(_repo_root)/${rest%/}"
}

# Two depths: <host>/<owner>/<repo>, and the <host>/<org>/<project>/<repo> that
# Azure DevOps needs.
_repo_rows() {
  local dir root
  root=$(_repo_root)
  for dir in "$root"/*/*/*(N/) "$root"/*/*/*/*(N/); do
    [[ -e $dir/.git ]] || continue
    printf 'repo %s\t%s\n' "${dir#"$root"/}" "$dir"
  done
  return 0
}

_repo_get() {
  local dest
  (($# == 1)) || {
    print 'usage: repo get <owner/repo|url>' >&2
    return 1
  }
  dest=$(_repo_dest "$1") || return 1
  if [[ ! -d $dest ]]; then
    git clone "$1" "$dest" || return 1
  fi
  cd -- "$dest"
}

_repo_pick() {
  local dir
  command -v fzf >/dev/null 2>&1 || {
    print 'repo: fzf is not installed' >&2
    return 1
  }
  dir=$(
    _repo_rows \
      | fzf --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --query "$*" \
        --prompt 'repo> ' \
        --preview "source ${_REPO_LIB}; _repo_preview {2}"
  )
  [[ -n $dir ]] || return 1
  cd -- "$dir"
}

_repo_preview() {
  local dir=${1:-}
  [[ -d $dir ]] || return 0
  print -r -- "$dir"
  print
  git -C "$dir" -c color.ui=always status --short --branch 2>/dev/null
  print
  git -C "$dir" log --oneline --decorate --color=always -15 2>/dev/null
  return 0
}

# repo [<query>...] : pick a repository and cd into it
# repo get <spec>   : clone into the root and cd into the clone
repo() {
  case ${1:-} in
    get)
      shift
      _repo_get "$@"
      ;;
    -h | --help | help)
      print 'usage: repo [<query>... | get <owner/repo|url>]'
      ;;
    *)
      _repo_pick "$@"
      ;;
  esac
}
