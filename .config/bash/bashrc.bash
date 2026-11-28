# Interactive bash: bash's own defaults plus each tool's stock init.
[[ $- == *i* ]] || return

# WSLg auto-sets WAYLAND_DISPLAY, but the socket is inaccessible in terminal sessions.
[[ -n $WSL_DISTRO_NAME ]] && unset WAYLAND_DISPLAY

# The XDG fallbacks cover a non-login shell whose parent never read bash_profile.
# Appending keeps concurrent shells from overwriting each other's history.
HISTFILE=${XDG_STATE_HOME:-$HOME/.local/state}/bash/history
mkdir -p "${HISTFILE%/*}"
HISTSIZE=10000
HISTCONTROL=ignoreboth
shopt -s histappend

alias du='du -h'
alias df='df -h'
alias ..='cd ..'
alias :q='exit'

# Ahead of the tools below, whose checks find mise-installed ones through it.
command -v mise >/dev/null && eval "$(mise activate bash)"

command -v fzf >/dev/null && eval "$(fzf --bash)"

if command -v eza >/dev/null; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --no-user --time-style=iso --group-directories-first'
  alias la='ll -a'
  alias ltr='ll --sort=modified'
  alias lst='ltr --reverse'
  alias tree='eza --tree --icons -I ".git" --group-directories-first'
fi

if command -v nvim >/dev/null; then
  # macOS man pipes into the pager even when its own stdout is not a terminal
  # (`man ls | rg`, agent shells), and nvim then waits for a UI that never comes.
  export MANPAGER='sh -c "if [ -t 1 ]; then exec nvim +Man!; else exec cat; fi"'
  alias v='nvim'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

if command -v starship >/dev/null; then
  export STARSHIP_CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}/starship/starship.toml
  export STARSHIP_CACHE=${XDG_CACHE_HOME:-$HOME/.cache}/starship/cache
  eval "$(starship init bash)"
fi
