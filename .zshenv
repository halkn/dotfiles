#####################################################################
# Enviroment Variables
#####################################################################
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less
export LSCOLORS=gxfxcxdxbxegedabagacad
export SHELL=zsh
#export LESS='--tabs=4 --no-init --LONG-PROMPT --ignore-case --quit-if-one-screen --RAW-CONTROL-CHARS'
#export LESS='-R -f -X -i -P ?f%f:(stdin). ?lb%lb?L/%L.. [?eEOF:?pb%pb\%..]'
export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSOPEN='| /usr/local/bin/src-hilite-lesspipe.sh %s'

# for Neovim
export XDG_CONGIG_HOME=~/.config

# for fzf
export FZF_DEFAULT_COMMAND='find . -type f'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border'
