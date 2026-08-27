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

# What git is handed to clone from. A spec carrying a `:` already names a host
# the way git reads it - a scheme or the scp-like `git@host:path` - and is passed
# through; a bare path is https, with the first segment read as a host when it
# looks like one and as a GitHub owner when it does not.
_repo_url() {
  local spec=${1:-}
  case $spec in
    *:*)
      print -r -- "$spec"
      ;;
    */*)
      if [[ ${spec%%/*} == *.* ]]; then
        print -r -- "https://$spec"
      else
        print -r -- "https://github.com/$spec"
      fi
      ;;
    *)
      print -r -- "$spec"
      ;;
  esac
}

# The listing is what is on GitHub, so the clones already under the root are
# marked rather than dropped: picking one is still a way to go to it. The mark
# is a path test, which keeps the list free of a process per row.
_repo_gh_rows() {
  local root nwo
  root=$(_repo_root)
  for nwo in "$@"; do
    if [[ -d $root/github.com/$nwo ]]; then
      printf '✓ %s\t%s\n' "$nwo" "$nwo"
    else
      printf '  %s\t%s\n' "$nwo" "$nwo"
    fi
  done
  return 0
}

_repo_gh_pick() {
  local spec out
  local -a repos
  command -v gh >/dev/null 2>&1 || {
    print 'repo: gh is not installed' >&2
    return 1
  }
  command -v fzf >/dev/null 2>&1 || {
    print 'repo: fzf is not installed' >&2
    return 1
  }
  # gh's own failure - not logged in, offline, rate limited - is what has to be
  # read, so the list is fetched before the picker opens rather than through a
  # pipe fzf would paint over.
  out=$(gh repo list --limit 200 --json nameWithOwner --jq '.[].nameWithOwner') || return 1
  repos=(${(f)out})
  ((${#repos})) || {
    print 'repo: gh listed no repositories' >&2
    return 1
  }
  spec=$(
    _repo_gh_rows "${repos[@]}" \
      | fzf --delimiter '\t' --with-nth 1 --accept-nth 2 --ansi \
        --prompt 'repo get> ' \
        --header '✓: already cloned' \
        --preview 'gh repo view {2}'
  )
  [[ -n $spec ]] || return 1
  print -r -- "$spec"
}

_repo_get() {
  local spec dest
  case $# in
    0)
      spec=$(_repo_gh_pick) || return 1
      ;;
    1)
      spec=$1
      ;;
    *)
      print 'usage: repo get [<owner/repo|url>]' >&2
      return 1
      ;;
  esac
  dest=$(_repo_dest "$spec") || return 1
  if [[ ! -d $dest ]]; then
    git clone "$(_repo_url "$spec")" "$dest" || return 1
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
# repo get          : pick one of your GitHub repositories to clone
repo() {
  case ${1:-} in
    get)
      shift
      _repo_get "$@"
      ;;
    -h | --help | help)
      print 'usage: repo [<query>... | get [<owner/repo|url>]]'
      ;;
    *)
      _repo_pick "$@"
      ;;
  esac
}
