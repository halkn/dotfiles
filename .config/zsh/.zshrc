# WSLg auto-sets WAYLAND_DISPLAY, but the socket is inaccessible in terminal sessions.
[[ -n $WSL_DISTRO_NAME ]] && unset WAYLAND_DISPLAY

# Keep zsh-owned state and cache under XDG directories.
zsh_data_dir=$XDG_DATA_HOME/zsh
zsh_state_dir=$XDG_STATE_HOME/zsh
zsh_cache_dir=$XDG_CACHE_HOME/zsh
mkdir -p "$zsh_state_dir"
mkdir -p "$zsh_cache_dir"
mkdir -p "$zsh_cache_dir/zcompcache"

# ── History ──────────────────────────────────────────
HISTFILE=$zsh_state_dir/history
_legacy_histfile=$zsh_data_dir/history
if [[ ! -e $HISTFILE && -f $_legacy_histfile ]]; then
  mv "$_legacy_histfile" "$HISTFILE" ||
    print 'zsh: failed to migrate history to XDG_STATE_HOME' >&2
fi
unset _legacy_histfile
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
alias ll='ls -lhF'
alias la='ls -lhAF'
alias du='du -h'
alias df='df -h'
alias ..='cd ..'
alias zs='exec zsh'
alias :q='exit'

# ── plugins (git clone) ───────────────────────────────
zsh_plugins_dir=$zsh_data_dir/plugins
[[ -f "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] &&
  source "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
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

# ── television ───────────────────────────────────────
# Only the shell-wide bits: the widgets and the completion. Workflows built on
# tv live under workflows/, its look in $XDG_CONFIG_HOME/television.
# The script calls compdef, so it has to come after compinit above.
if command -v tv >/dev/null 2>&1 && [[ -t 0 ]]; then
  # Provides the widgets: Ctrl-R (history) and Ctrl-T (completion of the buffer).
  source <(tv init zsh)

  # The generated completion leaves the channel argument to file names, which is
  # the one thing `tv` never takes there.
  _tv_channels() {
    local -a channels
    channels=(${(f)"$(tv list-channels 2>/dev/null)"})
    _describe -t channels 'channel' channels
  }
  compdef _tv_channels tv
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

# ── reviewr ──────────────────────────────────────────
if command -v herdr-reviewr >/dev/null 2>&1; then
  alias gd='herdr-reviewr'
fi

# ── workflows ────────────────────────────────────────
# Each file defines its functions unconditionally and checks its dependencies
# inside them, so no conditions belong here and the load order does not matter.
for _zsh_part in "$ZDOTDIR"/workflows/*.zsh(N); do
  source "$_zsh_part"
done
unset _zsh_part

# ── starship ─────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi

# ── machine-local overrides (not tracked in git) ─────
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# ── herdr ────────────────────────────────────────────
# `exec` replaces the shell, so this stays the last thing .zshrc does - which is
# also what lets .zshrc.local above turn the auto-start off.
# HERDR_ENV is set inside herdr-managed shells and stops the recursion.
HERDR_AUTO_START=${HERDR_AUTO_START:-1}

if command -v herdr >/dev/null 2>&1 &&
  [[ -o interactive ]] &&
  [[ -z $HERDR_ENV ]] &&
  [[ -t 0 ]] &&
  [[ -t 1 ]] &&
  [[ $HERDR_AUTO_START == 1 ]]; then
  exec herdr
fi
