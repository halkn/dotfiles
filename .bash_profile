# ---------------------------------------------------------------------------
# enviroment variables
# ---------------------------------------------------------------------------
# common
export LANG=en_US.UTF-8
export EDITOR=vim
export PAGER=less
export SHELL=bash

# XDG Base Directory
export XDG_CONFIG_HOME=~/.config
export XDG_DATA_HOME=~/.local/share
export XDG_CACHE_HOME=~/.cache

# golang
export GOPATH=$XDG_DATA_HOME/go
export GO111MODULE=on

# nodebrew
export NODEBREW_ROOT=$XDG_DATA_HOME/nodebrew

# npm
export NPM_HOME=$XDG_DATA_HOME/npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc

# RubyGems
export GEM_HOME="$XDG_DATA_HOME"/gem
export GEM_SPEC_CACHE="$XDG_CACHE_HOME"/gem

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

# homebrew
export HOMEBREW_NO_INSTALL_CLEANUP=1

# less
export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSHISTFILE=-

# fzf
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden -E .git -E .svn'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --preview-window=right:60%'

# ripgrep
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config

# ---------------------------------------------------------------------------↲
# start tmux↲
# ---------------------------------------------------------------------------↲
if [[ -z "$TMUX" ]]; then
  # PATH
  export PATH=$GOPATH/bin:$NODEBREW_ROOT/current/bin:$NPM_HOME/bin:$PATH
  if [[ -f /home/linuxbrew/.linuxbrew/bin/brew  ]]; then
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi

  # Cache result for $(brew --prefix)
  BREW_PREFIX=$(brew --prefix)
  export BREW_PREFIX

  # TMUX
  if type tmux > /dev/null 2>&1; then
    exec tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf
  fi
fi

# ---------------------------------------------------------------------------
# load bashrc
# ---------------------------------------------------------------------------
test -r ~/.local.bashrc && . ~/.local.bashrc
test -r ~/.bashrc && . ~/.bashrc
