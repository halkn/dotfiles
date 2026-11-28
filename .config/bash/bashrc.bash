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

set -o ignoreeof
# autocd needs bash 4+; macOS /bin/bash, still reachable as `bash`, lacks it.
shopt -s autocd 2>/dev/null
# Frees Ctrl-S from freezing the terminal; stty needs one to act on.
[[ -t 0 ]] && stty -ixon

alias du='du -h'
alias df='df -h'
alias ..='cd ..'
alias :q='exit'

# Ahead of the tools below, whose checks find mise-installed ones through it.
command -v mise >/dev/null && eval "$(mise activate bash)"

if command -v fzf >/dev/null; then
  export FZF_DEFAULT_OPTS="
    --height 60%
    --layout=reverse
    --border
    --info=inline
    --preview-window=right:60%:wrap
    --bind ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down
    --bind ctrl-/:toggle-preview
  "
fi

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

# flyline replaces readline, so it comes after every tool that sets up the prompt.
# macOS /bin/bash 3.2 cannot load it, and a shell without a terminal or without line editing
# (`--noediting`) has nothing to draw on; flyline refuses the latter and dumps its log.
# Already loaded is checked with `type -t`, not `enable flyline`: on bash 5.2+ a bare
# `enable flyline` loads a `flyline` file found on BASH_LOADABLES_PATH, whose default
# includes `.`, so a new shell would run one sitting in its start directory.
if ((BASH_VERSINFO[0] * 100 + BASH_VERSINFO[1] >= 404)) && [[ -t 0 && -t 1 ]] &&
  [[ -o emacs || -o vi ]] && [[ $(type -t flyline) != builtin ]]; then
  # The archive holds one versioned file: libflyline.dylib.<ver> or libflyline.so.<ver>.
  # Offline, because for a tool not yet installed mise asks GitHub for its versions. From
  # $HOME, because an untrusted mise config in the start directory makes `mise where` fail.
  _flyline=("$(MISE_OFFLINE=1 mise -C "$HOME" where github:HalFrgrd/flyline 2>/dev/null)"/libflyline.*)
  if [[ -f ${_flyline[0]} ]] && enable -f "${_flyline[0]}" flyline; then
    # flyline's default path comes from the OS data dir (~/Library on macOS); history
    # sits beside HISTFILE in the XDG state dir instead.
    flyline history --backend flyline \
      --jsonl-path "${XDG_STATE_HOME:-$HOME/.local/state}/flyline/history.jsonl"
    # readline's emacs keys that flyline leaves unbound or binds differently. Remaps make
    # the keys follow Up/Down/Left/Right in every context (history, menus, multi-line).
    flyline key remap Ctrl+p Up
    flyline key remap Ctrl+n Down
    flyline key remap Ctrl+b Left
    flyline key remap Ctrl+f Right
    flyline key bind Ctrl+h always=deleteLeft
    flyline key bind Alt+b always=moveLeftOneWordPart
    flyline key bind Alt+f always=moveRightOneWordPart
    flyline key bind Alt+d always=deleteRightOneWordPart
  fi
  unset _flyline
fi

# fzf's key bindings and `**<Tab>` work only under readline, so they are set up only
# where flyline did not load; flyline's history search and completion replace them.
if [[ $(type -t flyline) != builtin ]] && command -v fzf >/dev/null; then
  eval "$(fzf --bash)"
fi
