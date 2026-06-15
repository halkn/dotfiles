# Repository helpers using fzf + ghq.

# repo            : pick a ghq-managed repository with fzf and cd into it
# repo get <repo> : clone with ghq and cd into it (owner/repo or URL)
repo() {
  command -v ghq >/dev/null 2>&1 || {
    print 'repo: ghq is not installed or not in PATH' >&2
    return 1
  }

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

  dir=$(ghq list --full-path | fzf \
    --query="$*" \
    --preview 'eza --tree --level=1 --icons {} 2>/dev/null || ls -la {}') || return
  [[ -n "$dir" ]] && cd -- "$dir" && la
}
