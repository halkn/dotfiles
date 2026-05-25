# WSLg auto-sets WAYLAND_DISPLAY, but the socket is inaccessible in terminal sessions.
[[ -n $WSL_DISTRO_NAME ]] && unset WAYLAND_DISPLAY

# Keep zsh-owned runtime files under XDG directories.
zsh_data_dir=$XDG_DATA_HOME/zsh
mkdir -p "$zsh_data_dir"

# ── history ──────────────────────────────────────────
# size / dedup / share are declared in programs.zsh.history;
# hist_reduce_blanks has no native option so it stays here.
setopt hist_reduce_blanks

# ── options ──────────────────────────────────────────
setopt ignore_eof
setopt no_flow_control
setopt no_beep
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt list_rows_first
setopt numeric_glob_sort
setopt list_packed
setopt extended_glob
setopt long_list_jobs
setopt mark_dirs
setopt interactive_comments

# ── keybind ──────────────────────────────────────────
bindkey -e

# ── completion ───────────────────────────────────────
# compinit is run by programs.zsh (enableCompletion); only the zstyles we
# want stay here, since there is no native option for them.
zmodload -i zsh/complist

# Case-insensitive and partial-word matching.
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*'

# Highlighted menu selection on the second tab.
zstyle ':completion:*:default' menu select=2

# Shell-state wrappers stay as functions; action-only commands can be aliases.
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

if command -v fzx >/dev/null 2>&1; then
  alias frm='fzx rm'
  alias fgb='fzx git branch'
  alias fga='fzx git stage'
  alias fgl='fzx git log'
fi

# fgw - interactive worktree change directory
fgw() {
  local worktree

  _fzx_available || return
  worktree=$(fzx git worktree "$@") || return
  [[ -n "$worktree" ]] && cd -- "$worktree"
}

# ── repo ─────────────────────────────────────────────
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

# ── tmux ─────────────────────────────────────────────
ZSH_TMUX_AUTO_START=${ZSH_TMUX_AUTO_START:-1}
ZSH_TMUX_SESSION_NAME=${ZSH_TMUX_SESSION_NAME:-main}

if command -v tmux >/dev/null 2>&1 \
  && [[ -o interactive ]] \
  && [[ -z $TMUX ]] \
  && [[ -t 0 ]] \
  && [[ -t 1 ]] \
  && [[ $ZSH_TMUX_AUTO_START == 1 ]]; then
  # Replace the login shell only when this is a real interactive terminal.
  exec tmux new-session -A -s "$ZSH_TMUX_SESSION_NAME"
fi
