# ---------------------------------------------------------------------------
# enviroment variables
# ---------------------------------------------------------------------------
# common
export LANG=en_US.UTF-8
export EDITOR=vim
export PAGER=less
export SHELL=zsh

# XDG Base Directory
export XDG_CONFIG_HOME=~/.config
export XDG_CACHE_HOME=~/.cache
export XDG_DATA_HOME=~/.local/share

# zsh
export ZHOMEDIR=$XDG_CONFIG_HOME/zsh
export ZDATADIR=$XDG_DATA_HOME/zsh
export ZCACHEDIR=$XDG_CACHE_HOME/zsh
export HISTFILE=$XDG_DATA_HOME/zsh/history
export HISTSIZE=10000
export SAVEHIST=10000

# less
export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSHISTFILE=-

# ---------------------------------------------------------------------------
# path
# ---------------------------------------------------------------------------
typeset -U path
path=(
    $path
)
