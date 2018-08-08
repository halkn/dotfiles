#####################################################################
# export
#####################################################################
# Neovim
export XDG_CONGIG_HOME=~/.config
# ls cmd color
export LSCOLORS=gxfxcxdxbxegedabagacad
# Pager
export PAGER=less
# Less status line
export LESS='-R -f -X -i -P ?f%f:(stdin). ?lb%lb?L/%L.. [?eEOF:?pb%pb\%..]'
export LESSCHARSET='utf-8'
# LESS man page colors (makes Man pages more readable).
export LESS_TERMCAP_mb=$'\E[01;31m'
export LESS_TERMCAP_md=$'\E[01;31m'
export LESS_TERMCAP_me=$'\E[0m'
export LESS_TERMCAP_se=$'\E[0m'
export LESS_TERMCAP_so=$'\E[00;44;37m'
export LESS_TERMCAP_ue=$'\E[0m'
export LESS_TERMCAP_us=$'\E[01;32m'

#####################################################################
# editor
#####################################################################

# defaut editor is vim
export EDITOR=vim
# when not exist vim then start up vi
if ! type vim > /dev/null 2>&1; then
    alias vim=vi
fi

#####################################################################
# alias
#####################################################################
alias ls="ls -G"
alias ll="ls -lh"
alias la="ll -a"
alias vim="nvim"

