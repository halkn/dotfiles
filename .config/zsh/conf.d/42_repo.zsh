repo() {
  local cmd="${1:-cd}"
  (($# > 0)) && shift

  command -v fzx >/dev/null 2>&1 || {
    print 'repo: fzx is not installed or not in PATH' >&2
    return 1
  }

  case "$cmd" in
    cd)
      local dir
      dir=$(fzx repo cd "$@") || return
      [[ -n "$dir" ]] && cd -- "$dir" && la
      ;;
    get | list)
      fzx repo "$cmd" "$@"
      ;;
    *)
      print 'usage: repo <get|list|cd>' >&2
      return 1
      ;;
  esac
}
