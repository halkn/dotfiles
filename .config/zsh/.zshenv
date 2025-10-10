# ---------------------------------------------------------------------------
# enviroment variables
# ---------------------------------------------------------------------------
# common
export LANG=C.UTF-8
export EDITOR=vim
export PAGER=less
export SHELL=zsh

# XDG Base Directory
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.local/cache
export XDG_DATA_HOME=~/.local/share
export XDG_BIN_HOME=~/.local/bin

# zsh
export ZHOMEDIR=$XDG_CONFIG_HOME/zsh
export ZDATADIR=$XDG_DATA_HOME/zsh
export ZCACHEDIR=$XDG_CACHE_HOME/zsh
export HISTFILE=$XDG_DATA_HOME/zsh/history
export HISTSIZE=10000
export SAVEHIST=10000
export ZPLUGINDIR=$XDG_DATA_HOME/zsh_plugins

# node/npm
export NODE_ENV=production
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc
export NPM_BIN=$XDG_DATA_HOME/npm/bin

# uv
export UV_CACHE_DIR=$XDG_CACHE_HOME/uv
export UV_PYTHON_PREFERENCE=only-managed
export UV_PROJECT_ENVIRONMENT=.venv
export UV_COMPILE_BYTECODE=true
export UV_PROGRESS=auto
export UV_COLOR=auto

# less
export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSHISTFILE=-

# ---------------------------------------------------------------------------
# path
# ---------------------------------------------------------------------------
typeset -U path
path=(
  $XDG_BIN_HOME(N-/)
  $NPM_BIN(N-/)
  $path
)
