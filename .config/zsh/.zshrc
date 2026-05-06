# Keep zsh-owned runtime files under XDG directories.
zsh_data_dir=$XDG_DATA_HOME/zsh
zsh_cache_dir=$XDG_CACHE_HOME/zsh
zsh_plugin_dir=$XDG_DATA_HOME/zsh_plugins
mkdir -p "$zsh_data_dir"
mkdir -p "$zsh_cache_dir"
mkdir -p "$zsh_cache_dir/zcompcache"
mkdir -p "$zsh_plugin_dir"

# ── History ──────────────────────────────────────────
HISTFILE=$zsh_data_dir/history
HISTSIZE=100000
SAVEHIST=10000
setopt hist_expire_dups_first
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt share_history

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
autoload -Uz compinit
zmodload -i zsh/complist

_zcompdump="$zsh_cache_dir/.zcompdump"

# Rebuild the dump roughly daily; otherwise trust the cached dump for startup speed.
if [[ ! -s "$_zcompdump" || -n "$_zcompdump"(#qN.mh+23) ]]; then
  compinit -d "$_zcompdump"
else
  compinit -C -d "$_zcompdump"
fi

unset _zcompdump

zstyle ':completion:*:default' menu select=2
zstyle ':completion:*:default' list-colors ''

# Try exact completion first, then progressively looser matching.
zstyle ':completion:*' matcher-list \
  '' \
  'm:{a-zA-Z}={A-Za-z}' \
  'm:{a-zA-Z}={A-Za-z} r:|[._-]=* r:|=*'

zstyle ':completion:*' format '--- %d ---'
zstyle ':completion:*' group-name ''

zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$zsh_cache_dir/zcompcache"

zstyle ':completion:*' verbose yes

setopt complete_in_word

# Keep completers small; heavier fuzzy/correction completers are intentionally omitted.
zstyle ':completion:*' completer \
  _complete \
  _match \
  _prefix

# ── aliases ──────────────────────────────────────────
# ls
alias ls='ls --color=auto'
alias ll='ls -lhF'
alias la='ls -lhAF'
alias ltr='ls -lhFtr'

# human readable for du and df
alias du='du -h'
alias df='df -h'

# cd
alias ..='cd ..'

# etc
alias path='echo $PATH | tr ":" "\n"'
alias zs='exec zsh'
alias zb='for i in $(seq 1 10); do time zsh -i -c exit; done'
alias :q='exit'
dot() {
  local target="${XDG_CONFIG_HOME:-$HOME/.config}"

  [[ -d "$HOME/.dotfiles" ]] && target="$HOME/.dotfiles"

  cd "$target"
}

# ---------------------------------------------------------------------------
# zsh plugin manager
#
# To add a plugin:
#   1. Append "owner/repo" to _zsh_plugins
#   2. Append its entry file to _zsh_plugin_entries (fpath-only plugins skip step 2)
#   3. Run "zsh-plugin-install" to fetch any missing plugins
#
# To update all plugins:
#   zsh-plugin-update
# ---------------------------------------------------------------------------

_zsh_plugins=(
  zsh-users/zsh-autosuggestions
  zdharma-continuum/fast-syntax-highlighting # replaces zsh-syntax-highlighting
)

_zsh_plugin_entries=(
  zsh-autosuggestions/zsh-autosuggestions.zsh
  fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
)

zsh-plugin-install() {
  if ! command -v git >/dev/null 2>&1; then
    print "zsh: git is required to install plugins." >&2
    return 1
  fi

  local _p _d
  for _p in $_zsh_plugins; do
    _d=$zsh_plugin_dir/${_p#*/}
    if [[ ! -d $_d ]]; then
      print "installing: ${_p#*/}"
      git clone --depth 1 "https://github.com/$_p" "$_d" || return 1
    fi
  done
}

typeset -a _zsh_missing_plugins=()
for _p in $_zsh_plugins; do
  _d=$zsh_plugin_dir/${_p#*/}
  [[ -d $_d ]] || _zsh_missing_plugins+=("${_p#*/}")
done
unset _p _d

if ((${#_zsh_missing_plugins[@]} > 0)); then
  print "zsh: missing plugins: ${_zsh_missing_plugins[*]} (run: zsh-plugin-install)" >&2
fi
unset _zsh_missing_plugins

# Source plugins in entry order.
for _e in $_zsh_plugin_entries; do
  [[ -f $zsh_plugin_dir/$_e ]] && source $zsh_plugin_dir/$_e
done
unset _e

# Update all installed plugins
zsh-plugin-update() {
  if ! command -v git >/dev/null 2>&1; then
    print "zsh: git is required to update plugins." >&2
    return 1
  fi

  local _p _d
  for _p in $_zsh_plugins; do
    _d=$zsh_plugin_dir/${_p#*/}
    [[ -d $_d ]] && {
      print "updating: ${_p#*/}"
      git -C "$_d" pull --ff-only
    }
  done
}

# ── uv ───────────────────────────────────────────────
if command -v uv >/dev/null 2>&1; then
  _uv_comp=$zsh_cache_dir/completions/_uv
  _uv_bin=$(command -v uv)
  if [[ ! -f $_uv_comp || $_uv_bin -nt $_uv_comp ]]; then
    mkdir -p ${_uv_comp:h}
    uv generate-shell-completion zsh >$_uv_comp
  fi
  source $_uv_comp
  unset _uv_comp _uv_bin
fi

# ── lsd ──────────────────────────────────────────────
if command -v lsd >/dev/null 2>&1; then
  # Override the default ls aliases only when lsd is available.
  alias ls='lsd'
  alias ll='lsd -l'
  alias la='lsd -la'
  alias ltr='lsd -l --timesort --reverse'
  alias lst='lsd -l --timesort'
  alias tree='lsd --tree -I .git'
fi

# ── nvim ─────────────────────────────────────────────
if command -v nvim >/dev/null 2>&1; then
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
  alias v='nvim'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

# ── fzf ──────────────────────────────────────────────
export FZF_DEFAULT_OPTS="
  --height 60%
  --layout=reverse
  --border
  --info=inline
  --preview-window=right:60%:wrap
  --bind ctrl-u:preview-page-up,ctrl-d:preview-page-down
  --bind ctrl-/:toggle-preview
  --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
  --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
  --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
"

if command -v fzf >/dev/null 2>&1; then
  source <(fzf --zsh)
fi

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
export ZSH_TMUX_AUTO_START=${ZSH_TMUX_AUTO_START:-1}
export ZSH_TMUX_SESSION_NAME=${ZSH_TMUX_SESSION_NAME:-main}

if command -v tmux >/dev/null 2>&1 \
  && [[ -o interactive ]] \
  && [[ -z $TMUX ]] \
  && [[ -t 0 ]] \
  && [[ -t 1 ]] \
  && [[ $ZSH_TMUX_AUTO_START == 1 ]]; then
  # Replace the login shell only when this is a real interactive terminal.
  exec tmux new-session -A -s "$ZSH_TMUX_SESSION_NAME"
fi

# ── starship ─────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi

# compile zshrc.
[[ ! -f "${ZDOTDIR}/.zshrc.zwc" || "${ZDOTDIR}/.zshrc" -nt "${ZDOTDIR}/.zshrc.zwc" ]] \
  && zcompile "${ZDOTDIR}/.zshrc"
