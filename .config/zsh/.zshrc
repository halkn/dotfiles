#####################################################################
# auto zcompile
#####################################################################
if [ ! -f $ZDOTDIR/.zshrc.zwc -o $ZDOTDIR/.zshrc -nt $ZDOTDIR/.zshrc.zwc ]; then
  zcompile $ZDOTDIR/.zshrc
fi

#####################################################################
# Keybind
#####################################################################
# emacs key bind
bindkey -e

#####################################################################
# completion
#####################################################################
# load command completion function
autoload -Uz compinit
# load compinit
# compinit -d $XDG_CACHE_HOME/zsh/.zcompdump
compinit

# Choose a complementary candidate from the menu.
# select=2: Complement immediately
#           as soon as there are two or more completion candidates
zstyle ':completion:*:default' menu select=2

# Color a completion candidate
# '' : default colors
zstyle ':completion:*:default' list-colors ''

# ambiguous search when no match found
#   m:{a-z}={A-Z} : Ignore UperCace and LowerCase
#   r:|[._-]=*    : Complement it as having a wild card "*" before "." , "_" , "-"
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z} r:|[._-]=*'

# complection format
zstyle ':completion:*' format "--- %d ---"

# grouping for completion list
zstyle ':completion:*' group-name ''

# use cache
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path $XDG_CACHE_HOME/zsh/zcompcache

# use detailed completion
zstyle ':completion:*' verbose yes

# how to find the completion list?
# - _complete:      complete
# - _oldlist:       complete from previous result
# - _match:         complete from the suggestin without expand glob
# - _history:       complete from history
# - _ignored:       complete from ignored
# - _approximate:   complete from approximate suggestions
# - _prefix:        complete without caring the characters after carret
zstyle ':completion:*' completer \
  _complete \
  _match \
  _approximate \
  _oldlist \
  _history \
  _ignored \
  _prefix

#####################################################################
# alias
#####################################################################
# ls
alias ls='ls --color=auto'
alias ll='ls -lhF'
alias la='ls -lhAF'
alias ltr='ll -tr'

# nocorrect command
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'

# human readable for du and df
alias du='du -h'
alias df='df -h'

# cd
alias ..='cd ..'

# editor
if type nvim > /dev/null 2>&1; then
  alias vim=nvim
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
fi

# etc
alias path='echo $PATH | tr ":" "\n"'
alias zs='source $ZDOTDIR/.zshrc'
alias zb='for i in $(seq 1 10); do time zsh -i -c exit; done'
alias dot='cd $HOME/.dotfiles && $EDITOR'
alias :q='exit'

#####################################################################
# options
#####################################################################
# Ignore Ctrl-D logout from zsh
setopt ignore_eof
# Disable flow control
setopt no_flow_control
# beep off
setopt no_beep

# Ignore Duplication comannd when add history
setopt hist_ignore_dups
# No add history when beginning of line is space
setopt hist_ignore_space
# Reduce blanks when add history
setopt hist_reduce_blanks
# Expand history
setopt hist_expand
# Share command history across multiple Zsh sessions.
setopt share_history

# auto resume if suspend command exists
setopt auto_resume
# auto cd when input is only directory name
setopt auto_cd
# cd history pushd DIRSTACK
setopt auto_pushd

# complete list show horizontally
setopt list_rows_first
# complete sort numeric
setopt numeric_glob_sort
# Compact display of complete result
setopt list_packed

# Expand {} (ex. echo {a-c} -> a b c)
setopt brace_ccl
# Enable extended glob
setopt extended_glob
# Enable completion in "--option=arg"
setopt magic_equal_subst
# no glob expand when complete
setopt glob_complete

# command spellcheck
setopt correct
# jobs command default "jobs -l"
setopt long_list_jobs
# Add "/" if completes directory
setopt mark_dirs
# Enable redirection for multi files
setopt multios
# For multi byte
setopt print_eight_bit
# To treat '#' as comment in command line
setopt interactive_comments

#####################################################################
# plugins
#####################################################################
if [ -f $XDG_DATA_HOME/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source $XDG_DATA_HOME/zsh-autosuggestions/zsh-autosuggestions.zsh
fi 
if [ -f $XDG_DATA_HOME/zsh-syntax-highlighting//zsh-syntax-highlighting.zsh ]; then
  source $XDG_DATA_HOME/zsh-syntax-highlighting//zsh-syntax-highlighting.zsh
fi 


#####################################################################
# uv (for python)
#####################################################################
# for uv
if type uv > /dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)"
fi

#####################################################################
# prompt
#####################################################################
if type starship > /dev/null 2>&1; then
  eval "$(starship init zsh)"
fi

