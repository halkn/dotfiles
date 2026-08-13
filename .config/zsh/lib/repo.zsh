# repo - navigate repositories cloned under $REPO_ROOT. The listing and preview
# live here because herdr-repo-workspace.sh offers the same list when creating a
# workspace.
#
# This file is sourced from .zshrc and from
# ~/.config/herdr/herdr-repo-workspace.sh, so it must only define functions and
# must not touch the current shell state.

# Own path, so fzf preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_REPO_LIB=${${(%):-%x}:A}

_repo_root() {
  local root=${REPO_ROOT:-$HOME/repos}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

_repo_available() {
  command -v git >/dev/null 2>&1 || {
    print 'repo: git is not installed or not in PATH' >&2
    return 1
  }
  local root
  root=$(_repo_root)
  [[ -d $root ]] || {
    print "repo: $root does not exist (set REPO_ROOT)" >&2
    return 1
  }
}

# One row per repository: `<path without host><TAB>full path`. The host is
# dropped from the label because it is rarely what distinguishes two clones.
_repo_rows() {
  local root marker rel
  root=$(_repo_root)
  # host/owner/repo (GitHub and friends) and host/org/project/repo (Azure DevOps).
  # A fixed depth keeps nested repositories such as vendored node_modules out.
  for marker in $root/*/*/*/.git(N) $root/*/*/*/*/.git(N); do
    rel=${${marker:h}#$root/}
    printf '%s\t%s\n' "${rel#*/}" "${marker:h}"
  done
}

# Preview body for a repository, shared by `repo` and the herdr picker.
_repo_preview() {
  local dir=$1
  eza --tree --level=1 --icons "$dir" 2>/dev/null || ls -la "$dir"
}

# Print the path of an interactively selected repository. $1 is an initial query.
_repo_pick() {
  print -r -- "$(_repo_rows)" \
    | fzf --delimiter '\t' --with-nth 1 \
      --query="${1:-}" \
      --prompt 'repo> ' \
      --preview "source ${_REPO_LIB}; _repo_preview {2}" \
    | awk -F'\t' '{print $2}'
}

# Map `owner/repo` or a clone URL to the checkout path under the root.
# Azure DevOps is normalized twice over: the `_git` segment is an artifact of its
# URL scheme, and its SSH host/`v3` prefix would otherwise place the same
# repository somewhere else than the HTTPS URL does.
_repo_dest() {
  local arg=$1 rest host path

  if [[ $arg != *:* && $arg == */* && $arg != */*/* ]]; then
    host=github.com
    path=$arg
  elif [[ $arg == *://* ]]; then
    rest=${arg#*://}
    host=${rest%%/*}
    path=${rest#*/}
  elif [[ $arg == *:* ]]; then
    host=${arg%%:*}
    path=${arg#*:}
  else
    print "repo: cannot derive a path from '$arg'" >&2
    return 1
  fi

  host=${host#*@}
  host=${host%%:*}
  if [[ $host == ssh.dev.azure.com ]]; then
    host=dev.azure.com
    path=${path#v3/}
  fi
  path=${path#/}
  path=${path%/}
  path=${path%.git}
  path=${path//\/_git\//\/}

  [[ -n $host && -n $path ]] || {
    print "repo: cannot derive a path from '$arg'" >&2
    return 1
  }
  print -r -- "$(_repo_root)/$host/$path"
}

# repo            : pick a repository with fzf and cd into it
# repo get <repo> : clone into the root and cd into it (owner/repo or URL)
repo() {
  _repo_available || return 1

  local dir
  if [[ "$1" == get ]]; then
    shift
    (($# == 1)) || {
      print 'usage: repo get <owner/repo|url>' >&2
      return 1
    }
    dir=$(_repo_dest "$1") || return 1
    if [[ ! -d $dir ]]; then
      local url=$1
      # Only the bare shorthand needs a URL built; anything else is already one,
      # and rewriting it would drop the credentials the user picked.
      [[ $url == *:* ]] || url=https://github.com/$url
      git clone "$url" "$dir" || return
    fi
    cd -- "$dir" && la
    return
  fi

  command -v fzf >/dev/null 2>&1 || {
    print 'repo: fzf is not installed' >&2
    return 1
  }
  dir=$(_repo_pick "$*") || return
  [[ -n "$dir" ]] && cd -- "$dir" && la
}
