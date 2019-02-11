#####################################################################
# init
#####################################################################
# skip load /etc/z*
setopt no_global_rcs

#####################################################################
# Enviroment Variables
#####################################################################
# common
export LANG=en_US.UTF-8
export EDITOR=vim
export PAGER=less
export SHELL=zsh

# XDG Base Directory
export XDG_CONFIG_HOME=~/.config
export XDG_DATA_HOME=~/.local/share
export XDG_CACHE_HOME=~/.cache

# zsh
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# golang
export GOPATH=$HOME/dev/go

# PATH
typeset -U path
path=(
    /usr/local/opt/coreutils/libexec/gnubin(N-/)
    /usr/local/bin
    /usr/bin
    /bin
    /usr/sbin
    /sbin
    $GOPATH/bin(N-/)
    $path
)

# less
export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSHISTFILE=-

# fzf
export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!{.git,.svn}"'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

