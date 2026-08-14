# repo - navigate repositories cloned under $REPO_ROOT. The listing and preview
# live here because herdr-repo-workspace.sh offers the same list when creating a
# workspace.
#
# This file is sourced from .zshrc and from
# ~/.config/herdr/herdr-repo-workspace.sh, so it must only define functions and
# must not touch the current shell state. For the same reason it never returns
# early on a missing dependency: the picker would lose `_repo_pick` silently.

# Own path, so tv preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_REPO_LIB=${${(%):-%x}:A}

_repo_root() {
  local root=${REPO_ROOT:-$HOME/repos}
  root=${root/#\~/$HOME}
  print -r -- "${root%/}"
}

# `repo get` only needs git: cloning creates the root, so requiring it up front
# would leave a fresh machine unable to make its first checkout.
_repo_git_available() {
  command -v git >/dev/null 2>&1 || {
    print 'repo: git is not installed or not in PATH' >&2
    return 1
  }
}

# Picking, on the other hand, has nothing to offer without tv and a root.
_repo_picker_available() {
  command -v tv >/dev/null 2>&1 || {
    print 'repo: tv is not installed' >&2
    return 1
  }
  local root
  root=$(_repo_root)
  [[ -d $root ]] || {
    print "repo: $root does not exist (set REPO_ROOT)" >&2
    return 1
  }
}

# Layouts a clone can have below the root: host/owner/repo (GitHub and friends)
# and host/org/project/repo (Azure DevOps). Fixed depths keep nested
# repositories such as vendored node_modules out of the list.
_REPO_DEPTHS=('*/*/*' '*/*/*/*')

# One row per repository: `<path without host><TAB>full path`. The host is
# dropped from the label because it is rarely what distinguishes two clones.
_repo_rows() {
  local root marker rel
  root=$(_repo_root)
  for marker in $root/${~^_REPO_DEPTHS}/.git(N); do
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
# The output template prints the path, so nothing has to run downstream of tv
# and mask its exit status when the picker is cancelled. The preview is spawned
# through $SHELL, which is not necessarily zsh, hence the explicit `zsh -c`.
_repo_pick() {
  local rows
  rows=$(_repo_rows)
  [[ -n $rows ]] || return 1
  print -r -- "$rows" \
    | tv --source-display '{split:\t:0}' --source-output '{split:\t:1}' \
      --input "${1:-}" \
      --input-prompt 'repo> ' \
      --preview-command "zsh -c 'source ${_REPO_LIB}; _repo_preview \"{split:\t:1}\"'"
}

# Fold the forge-specific spellings of one repository onto a single host/path.
# Azure DevOps is normalized twice over: the `_git` segment is an artifact of its
# URL scheme, and its SSH host/`v3` prefix would otherwise place the same
# repository somewhere else than the HTTPS URL does.
_repo_normalize() {
  local host=$1 path=$2
  if [[ $host == ssh.dev.azure.com ]]; then
    host=dev.azure.com
    path=${path#v3/}
  fi
  path=${path//\/_git\//\/}
  reply=("$host" "$path")
}

# Split `owner/repo` or a clone URL into `reply=(host path url)`. No root, no
# filesystem, no output: everything that decides where a repository lands is
# here so that .config/zsh/test/repo_test.zsh can pin it down.
_repo_parse() {
  local arg=$1 rest host path url=$1

  if [[ $arg != *:* && $arg == */* && $arg != */*/* ]]; then
    host=github.com
    path=$arg
    # Only the bare shorthand needs a URL built; anything else is already one,
    # and rewriting it would drop the credentials the user picked.
    url=https://github.com/$arg
  elif [[ $arg == *://* ]]; then
    rest=${arg#*://}
    host=${rest%%/*}
    path=${rest#*/}
  elif [[ $arg == *:* ]]; then
    host=${arg%%:*}
    path=${arg#*:}
  else
    return 1
  fi

  host=${host#*@}
  host=${host%%:*}
  path=${path#/}
  path=${path%/}
  path=${path%.git}
  _repo_normalize "$host" "$path"

  [[ -n $reply[1] && -n $reply[2] ]] || return 1
  reply=("$reply[1]" "$reply[2]" "$url")
}

# Checkout path of an already parsed host/path pair.
_repo_dest() {
  print -r -- "$(_repo_root)/$1/$2"
}

# Clone into the root and cd into it. `owner/repo` or any clone URL.
_repo_get() {
  local dir
  local -a reply
  (($# == 1)) || {
    print 'usage: repo get <owner/repo|url>' >&2
    return 1
  }
  _repo_git_available || return 1
  _repo_parse "$1" || {
    print "repo: cannot derive a path from '$1'" >&2
    return 1
  }

  dir=$(_repo_dest "$reply[1]" "$reply[2]")
  if [[ ! -d $dir ]]; then
    mkdir -p -- "${dir:h}" || return 1
    git clone "$reply[3]" "$dir" || return 1
  fi
  cd -- "$dir"
}

_repo_go() {
  local dir
  _repo_picker_available || return 1
  dir=$(_repo_pick "$*") || return 1
  [[ -n $dir ]] || return 1
  cd -- "$dir"
}

# repo               : pick a repository with tv and cd into it
# repo <words...>    : same, with the words as the initial picker query
# repo get <repo>    : clone into the root and cd into it (owner/repo or URL)
#
# `get` and the help flags are the only reserved words; anything else is a
# query, so `repo dotfiles` narrows the picker instead of failing.
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
      _repo_go "$@"
      ;;
  esac
}

# dot - jump to this dotfiles checkout, which lives under the same root.
dot() {
  cd -- "$(_repo_root)/github.com/halkn/dotfiles"
}
