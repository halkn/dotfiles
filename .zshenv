#####################################################################
# Enviroment Variables
#####################################################################
if [ -z $TMUX ]; then
    export LANG=en_US.UTF-8
    export EDITOR=vim
    export PAGER=less
    export LSCOLORS=gxfxcxdxbxegedabagacad
    export SHELL=zsh

    # less
    export LESS='-g -i -M -R -S -W -z-4 -x4'
    export LESSOPEN='| /usr/local/bin/src-hilite-lesspipe.sh %s'
    export LESSHISTFILE=-

    # XDG Base Directory
    export XDG_CONFIG_HOME=~/.config
    export XDG_DATA_HOME=~/.local/share
    export XDG_CACHE_HOME=~/.cache

    # fzf
    export FZF_DEFAULT_COMMAND='rg --files --hidden --glob "!.git"'
    export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'

    # zsh
    export ZDOTDIR=$XDG_CONFIG_HOME/zsh
fi
