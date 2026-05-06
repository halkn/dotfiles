if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

_fzx_available() {
  command -v fzx >/dev/null 2>&1 || {
    print 'zsh: fzx is not installed or not in PATH' >&2
    return 1
  }
}

# fh - repeat history
fh() {
  local command

  _fzx_available || return
  command=$(fc -l 1 | fzx history) || return
  [[ -n "$command" ]] && print -z -- "$command"
}

# fcd - interactive change directory
fcd() {
  local dir

  _fzx_available || return
  dir=$(fzx cd "$@") || return
  [[ -n "$dir" ]] && cd -- "$dir"
}

# frm - interactive remove files
frm() {
  _fzx_available || return
  fzx rm "$@"
}

# fgb - interactive git branch switch
fgb() {
  _fzx_available || return
  fzx git branch "$@"
}

# fga - interactive git stage/unstage
fga() {
  _fzx_available || return
  fzx git stage "$@"
}

# fgl - interactive git log
fgl() {
  _fzx_available || return
  fzx git log "$@"
}

# fgw - interactive worktree change directory
fgw() {
  local worktree

  _fzx_available || return
  worktree=$(fzx git worktree "$@") || return
  [[ -n "$worktree" ]] && cd -- "$worktree"
}
