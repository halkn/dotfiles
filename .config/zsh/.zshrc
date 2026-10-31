# WSLg auto-sets WAYLAND_DISPLAY, but the socket is inaccessible in terminal sessions.
[[ -n $WSL_DISTRO_NAME ]] && unset WAYLAND_DISPLAY

# Keep zsh-owned state and cache under XDG directories.
zsh_data_dir=$XDG_DATA_HOME/zsh
zsh_state_dir=$XDG_STATE_HOME/zsh
zsh_cache_dir=$XDG_CACHE_HOME/zsh
mkdir -p "$zsh_state_dir" "$zsh_cache_dir/zcompcache"

# ── History ──────────────────────────────────────────
HISTFILE=$zsh_state_dir/history
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
alias du='du -h'
alias df='df -h'
alias ..='cd ..'
alias zs='exec zsh'
alias :q='exit'

# ── mise ─────────────────────────────────────────────
# Ahead of every tool below: activation sets PATH there and then, and the
# checks for each tool that follow find mise-installed ones through it.
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate zsh)"
fi

# ── generated completions (uv, bun) ──────────────────
# Each entry is the command that prints a tool's completion script, cached
# until the tool's binary is newer. Sourced at the top level rather than from a
# function, where the script's typesets would turn local.
# `bun completions` prints the script only when stdout is not a TTY; on a TTY it
# installs the file itself and appends a source line to .zshrc.
for _comp in 'uv generate-shell-completion zsh' 'bun completions'; do
  _comp_cmd=(${(z)_comp})
  ((${+commands[${_comp_cmd[1]}]})) || continue
  _comp_cache=$zsh_cache_dir/${_comp_cmd[1]}_completion.zsh
  # A failed run is not cached, or every new shell would source its output
  # until the binary changes; the previous script, if any, stays.
  if [[ ! -s $_comp_cache || ${commands[${_comp_cmd[1]}]} -nt $_comp_cache ]]; then
    if "${_comp_cmd[@]}" >|"$_comp_cache.new"; then
      mv -f -- "$_comp_cache.new" "$_comp_cache"
    else
      rm -f -- "$_comp_cache.new"
    fi
  fi
  [[ -s $_comp_cache ]] && source "$_comp_cache"
done
unset _comp _comp_cmd _comp_cache

# ── fzf ──────────────────────────────────────────────
# The shell-wide bits: the widgets, the look, and the per-command completion
# sources. Full-screen pickers live in .config/herdr/. The integration script
# calls compdef, so it has to come after compinit above.
if command -v fzf >/dev/null 2>&1 && [[ -t 0 ]]; then
  export FZF_DEFAULT_OPTS="
    --height 60%
    --layout=reverse
    --border
    --info=inline
    --preview-window=right:60%:wrap
    --bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
    --bind ctrl-/:toggle-preview
  "

  # Provides the widgets: Ctrl-R (history), Ctrl-T (paste paths), Alt-C (cd).
  source <(fzf --zsh)

  # `<command> **<TAB>` is where selecting plus one command lives, so those need
  # no function of their own: the source and the preview follow the command
  # being completed.

  # Preview for the completions whose source is the default path walker.
  _fzf_comprun() {
    local cmd=$1
    shift
    case $cmd in
      cd | rmdir)
        fzf --preview 'ls -la {}' "$@"
        ;;
      # bat is not installed here, hence cat.
      cat | less | head | tail | cp | mv | rm | touch | chmod | ln | tar | zip | unzip | nvim | v)
        fzf --preview 'cat {}' "$@"
        ;;
      *)
        fzf "$@"
        ;;
    esac
  }

  # Git has no `_fzf_complete_git` here: branch and commit pickers are
  # `git fz switch` / `git fz log` / `git fz stage`. Without the function,
  # `git **<TAB>` falls back to fzf's own path completion.

  # `hw branch|pr|rm **<TAB>`: the rows `hw` serves, of which the last column is
  # what goes on the command line. Anything else is a path, with the word being
  # completed in $prefix, which fzf sets for the call.
  _fzf_complete_hw() {
    local -a words=(${(z)1})
    case ${words[2]-} in
      branch)
        _fzf_complete --delimiter '\t' --with-nth 1 -- "$@" < <(hw branches 2>/dev/null)
        ;;
      pr)
        _fzf_complete --delimiter '\t' --with-nth 1 -- "$@" < <(hw prs 2>/dev/null)
        ;;
      rm)
        _fzf_complete --multi --delimiter '\t' --with-nth 1 -- "$@" < <(hw list 2>/dev/null)
        ;;
      *)
        _fzf_path_completion "${prefix:-}" "$@"
        ;;
    esac
  }
  _fzf_complete_hw_post() {
    cut -f2
  }
fi

# ── eza ──────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --no-user --time-style=iso --group-directories-first'
  alias la='eza -la --icons --git --no-user --time-style=iso --group-directories-first'
  alias ltr='eza -l --icons --git --no-user --time-style=iso --sort=modified --group-directories-first'
  alias lst='eza -l --icons --git --no-user --time-style=iso --sort=modified --reverse --group-directories-first'
  alias tree='eza --tree --icons -I ".git" --group-directories-first'
else
  alias ll='ls -lhF'
  alias la='ls -lhAF'
fi

# ── nvim ─────────────────────────────────────────────
if command -v nvim >/dev/null 2>&1; then
  # macOS man pipes into the pager even when its own stdout is not a terminal
  # (`man ls | rg`, agent shells), and nvim then waits for a UI that never comes.
  export MANPAGER='sh -c "if [ -t 1 ]; then exec nvim +Man!; else exec cat; fi"'
  alias v='nvim'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

# ── starship ─────────────────────────────────────────
if command -v starship >/dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi

# ── plugins (git clone) ───────────────────────────────
# Last of the widgets: fast-syntax-highlighting wraps only the widgets that
# exist when it is sourced, so one defined after it (fzf's) would leave the
# line unhighlighted once it runs.
zsh_plugins_dir=$zsh_data_dir/plugins
[[ -f "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] &&
  source "$zsh_plugins_dir/zsh-autosuggestions/zsh-autosuggestions.zsh"

[[ -f "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh" ]] &&
  source "$zsh_plugins_dir/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"

# ── machine-local overrides (not tracked in git) ─────
[[ -f "$ZDOTDIR/.zshrc.local" ]] && source "$ZDOTDIR/.zshrc.local"

# After .zshrc.local, which may still use them.
unset zsh_data_dir zsh_state_dir zsh_cache_dir zsh_plugins_dir

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
