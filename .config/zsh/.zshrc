# mkdir for zsh.
mkdir -p "${ZDATADIR}"
mkdir -p "${ZCACHEDIR}"
mkdir -p "${ZPLUGINDIR}"

# ── History ──────────────────────────────────────────
export HISTFILE=$XDG_DATA_HOME/zsh/history
export HISTSIZE=100000
export SAVEHIST=10000
setopt hist_expire_dups_first
setopt hist_save_no_dups
setopt hist_find_no_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks
setopt hist_expand
setopt share_history

# ── options ──────────────────────────────────────────
setopt ignore_eof
setopt no_flow_control
setopt no_beep
setopt auto_resume
setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt list_rows_first
setopt numeric_glob_sort
setopt list_packed
setopt brace_ccl
setopt extended_glob
setopt magic_equal_subst
setopt glob_complete
setopt correct
setopt long_list_jobs
setopt mark_dirs
setopt interactive_comments

# ── keybind ──────────────────────────────────────────
bindkey -e

# ── completion ───────────────────────────────────────
autoload -Uz compinit
# load compinit with XDG cache location for dump file
# skip regeneration if dump file is less than 24 hours old
if [[ -n $ZCACHEDIR/.zcompdump(#qN.mh+24) ]]; then
  compinit -d $ZCACHEDIR/.zcompdump
else
  compinit -C -d $ZCACHEDIR/.zcompdump
fi

# Choose a completion candidate from the menu.
# select=2: Complete immediately
#           as soon as there are two or more completion candidates
zstyle ':completion:*:default' menu select=2

# Color a completion candidate
# '' : default colors
zstyle ':completion:*:default' list-colors ''

# ambiguous search when no match found
#   m:{a-z}={A-Z} : Ignore UperCace and LowerCase
#   r:|[._-]=*    : Complement it as having a wild card "*" before "." , "_" , "-"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} r:|[._-]=*'

# completion format
zstyle ':completion:*' format "--- %d ---"

# grouping for completion list
zstyle ':completion:*' group-name ''

# use cache
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $ZCACHEDIR/zcompcache

# use detailed completion
zstyle ':completion:*' verbose yes

# how to find the completion list?
# - _complete:      complete
# - _oldlist:       complete from previous result
# - _match:         complete from the suggestin without expand glob
# - _history:       complete from history
# - _ignored:       complete from ignored
# - _approximate:   complete from approximate suggestions
# - _prefix:        complete without caring the characters after carret
zstyle ':completion:*' completer \
  _complete \
  _match \
  _oldlist \
  _history \
  _ignored \
  _prefix \
  _approximate

# ── aliases ──────────────────────────────────────────
# ls
alias ls='ls --color=auto'
alias ll='ls -lhF'
alias la='ls -lhAF'
alias ltr='ls -lhFtr'

# nocorrect command
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'

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
    _d=$ZPLUGINDIR/${_p#*/}
    if [[ ! -d $_d ]]; then
      print "installing: ${_p#*/}"
      git clone --depth 1 "https://github.com/$_p" "$_d" || return 1
    fi
  done
}

typeset -a _zsh_missing_plugins=()
for _p in $_zsh_plugins; do
  _d=$ZPLUGINDIR/${_p#*/}
  [[ -d $_d ]] || _zsh_missing_plugins+=("${_p#*/}")
done
unset _p _d

if ((${#_zsh_missing_plugins[@]} > 0)); then
  print "zsh: missing plugins: ${_zsh_missing_plugins[*]} (run: zsh-plugin-install)" >&2
fi
unset _zsh_missing_plugins

# Source plugins (order matters)
for _e in $_zsh_plugin_entries; do
  [[ -f $ZPLUGINDIR/$_e ]] && source $ZPLUGINDIR/$_e
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
    _d=$ZPLUGINDIR/${_p#*/}
    [[ -d $_d ]] && {
      print "updating: ${_p#*/}"
      git -C "$_d" pull --ff-only
    }
  done
}

# ── uv ───────────────────────────────────────────────
if command -v uv >/dev/null 2>&1; then
  _uv_comp=$ZCACHEDIR/completions/_uv
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
