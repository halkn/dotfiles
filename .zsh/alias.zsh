#####################################################################
# alias
#####################################################################

# Util
alias ll="ls -lh"
alias la="ll -a"
alias vim="nvim"

# when not exist vim then start up vi
if ! type vim > /dev/null 2>&1; then
    alias vim=vi
fi
