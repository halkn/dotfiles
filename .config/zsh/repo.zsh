# repo - navigate ghq-managed repositories. The listing and preview live here
# because herdr-repo-workspace.sh offers the same list when creating a workspace.
#
# This file is sourced from .zshrc and from
# ~/.config/herdr/herdr-repo-workspace.sh, so it must only define functions and
# must not touch the current shell state.

# Own path, so fzf preview commands (which run in a fresh shell without these
# functions) can re-source it. `%x` expands to the file being sourced.
_REPO_LIB=${${(%):-%x}:A}

_repo_available() {
  command -v ghq >/dev/null 2>&1 || {
    print 'repo: ghq is not installed or not in PATH' >&2
    return 1
  }
}

# One row per repository: `owner/repo<TAB>full path`. The ghq tree is
# host/owner/repo, so the two trailing components identify it well enough.
_repo_rows() {
  local dir
  ghq list --full-path | while IFS= read -r dir; do
    printf '%s\t%s\n' "${dir:h:t}/${dir:t}" "$dir"
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

# repo            : pick a ghq-managed repository with fzf and cd into it
# repo get <repo> : clone with ghq and cd into it (owner/repo or URL)
repo() {
  _repo_available || return 1

  local dir
  if [[ "$1" == get ]]; then
    shift
    (($#)) || {
      print 'usage: repo get <owner/repo|url>' >&2
      return 1
    }
    ghq get "$@" || return
    # --exact resolves owner/repo to its full path; URLs may not match, so cd is best-effort.
    dir=$(ghq list --full-path --exact "${@[-1]}" 2>/dev/null | head -1)
    [[ -n "$dir" ]] && cd -- "$dir" && la
    return
  fi

  command -v fzf >/dev/null 2>&1 || {
    print 'repo: fzf is not installed' >&2
    return 1
  }
  dir=$(_repo_pick "$*") || return
  [[ -n "$dir" ]] && cd -- "$dir" && la
}
