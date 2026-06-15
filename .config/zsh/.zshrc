# WSLg auto-sets WAYLAND_DISPLAY, but the socket is inaccessible in terminal sessions.
[[ -n $WSL_DISTRO_NAME ]] && unset WAYLAND_DISPLAY

# Keep zsh-owned runtime files under XDG directories.
zsh_data_dir=$XDG_DATA_HOME/zsh
zsh_cache_dir=$XDG_CACHE_HOME/zsh
mkdir -p "$zsh_data_dir"
mkdir -p "$zsh_cache_dir"
mkdir -p "$zsh_cache_dir/zcompcache"

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
alias ll='ls -lhF'
alias la='ls -lhAF'

# human readable for du and df
alias du='du -h'
alias df='df -h'

# cd
alias ..='cd ..'

# etc
alias zs='exec zsh'
alias :q='exit'
dot() {
  local target="${XDG_CONFIG_HOME:-$HOME/.config}"

  [[ -d "$HOME/.dotfiles" ]] && target="$HOME/.dotfiles"

  cd "$target"
}

# ── plugins (git clone) ───────────────────────────────
zsh_plugins_dir=$zsh_data_dir/plugins
[[ -f "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] \
  && source "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] \
  && source "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

if command -v mise >/dev/null 2>&1; then
  eval "$(~/.local/bin/mise activate zsh)"
fi

# ── uv ───────────────────────────────────────────────
if command -v uv >/dev/null 2>&1; then
  _uv_comp="$zsh_cache_dir/uv_completion.zsh"
  if [[ ! -s "$_uv_comp" || "$(command -v uv)" -nt "$_uv_comp" ]]; then
    uv generate-shell-completion zsh >|"$_uv_comp"
  fi
  source "$_uv_comp"
  unset _uv_comp
fi

# ── eza ──────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --no-user --time-style=iso --group-directories-first'
  alias la='eza -la --icons --git --no-user --time-style=iso --group-directories-first'
  alias ltr='eza -l --icons --git --no-user --time-style=iso --sort=modified --group-directories-first'
  alias lst='eza -l --icons --git --no-user --time-style=iso --sort=modified --reverse --group-directories-first'
  alias tree='eza --tree --icons -I ".git" --group-directories-first'
fi

# ── nvim ─────────────────────────────────────────────
if command -v nvim >/dev/null 2>&1; then
  export MANPAGER='nvim +Man!'
  alias v='nvim'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

# ── fzf (modules under lib/) ─────────────────────────
# Built-in widgets (Ctrl-R history, Alt-C cd, Ctrl-T paste) come from fzf-core.zsh.
if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]]; then
  for _fzf_mod in "$ZDOTDIR"/lib/fzf-*.zsh(N); do
    source "$_fzf_mod"
  done
  unset _fzf_mod
fi

# ── repo ─────────────────────────────────────────────
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

  command -v fzf >/dev/null 2>&1 || {
    print 'repo: fzf is not installed or not in PATH' >&2
    return 1
  }
  dir=$(ghq list --full-path | fzf \
    --query="$*" \
    --preview 'eza --tree --level=1 --icons {} 2>/dev/null || ls -la {}') || return
  [[ -n "$dir" ]] && cd -- "$dir" && la
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

# ── starship ─────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi

# ── machine-local overrides (not tracked in git) ─────
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"
