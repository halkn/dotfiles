
#####################################################################
# init
#####################################################################
# auto zcompile
if [ ! -f $ZDOTDIR/.zshrc.zwc -o $ZDOTDIR/.zshrc -nt $ZDOTDIR/.zshrc.zwc ]; then
    zcompile $ZDOTDIR/.zshrc
fi

#####################################################################
# General Setting
#####################################################################
umask 022

#####################################################################
# completion
#####################################################################
# load command completion function
autoload -Uz compinit
# load compinit
compinit

# Choose a complementary candidate from the menu.
# select=2: Complement immediately
#           as soon as there are two or more completion candidates
zstyle ':completion:*:default' menu select=2

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
# ls setting
#####################################################################
if [ -n "${LS_COLORS}" ]; then
    alias ls="ls --color=auto"
    zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
elif [ -n "{$LSCOLORS}" ]; then
    alias ls="ls -G"
    zstyle ':completion:*' list-colors $LSCOLORS
fi

#####################################################################
# alias
#####################################################################
# nocorrect command
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'

# Util
alias ll="ls -lh"
alias la="ll -a"
#alias vim="nvim"

# human readable for du and df
alias du="du -h"
alias df="df -h"

#####################################################################
# options
#####################################################################
# Ignore Ctrl-D logout from zsh
setopt ignore_eof
# auto resume if suspend command exists
setopt auto_resume
# beep off
setopt no_beep
# Expand {} (ex. echo {a-c} -> a b c)
setopt brace_ccl
# command spellcheck 
setopt correct
# Disable flow control
setopt no_flow_control
# Ignore Duplication comannd when add history
setopt hist_ignore_dups
# No add history when beginning of line is space
setopt hist_ignore_space
# Reduce blanks when add history
setopt hist_reduce_blanks
# jobs command default "jobs -l"
setopt long_list_jobs
# Enable completion in "--option=arg"
setopt magic_equal_subst
# Add "/" if completes directory
setopt mark_dirs
# complete list show horizontally
setopt list_rows_first
# Enable redirection for multi files
setopt multios
# For multi byte
setopt print_eightbit
# no glob expand when complete
setopt glob_complete
# Expand history
setopt hist_expand 
# complete sort numeric
setopt numeric_glob_sort
# autp cd when input is only directory name 
setopt auto_cd
# cd history pushd DIRSTACK
setopt auto_pushd
# Compact display of complete result
setopt list_packed
# To treat '#' as comment in command line
setopt interactive_comments
# Enable extended glob
setopt extended_glob

# history
HISTFILE=$XDG_DATA_HOME/zsh/history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history

#####################################################################
# function
#####################################################################

# interactive cd
function cd() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(echo ".." && ls -ap | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --preview '
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls -p -FG "${__cd_path}";
        ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
}

#####################################################################
# zplugin
#####################################################################
# Instaling zplugin
if [ ! -e $HOME/.zplugin ]; then
    git clone https://github.com/zdharma/zplugin.git ~/.zplugin/bin
fi

# Initialize
source $HOME/.zplugin/bin/zplugin.zsh
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin

# Theme
zplugin ice pick"async.zsh" src"pure.zsh"
zplugin light sindresorhus/pure

# Load zsh plugins
zplugin light zsh-users/zsh-syntax-highlighting
zplugin light zsh-users/zsh-autosuggestions

# Lazy load zsh plugins
zplugin ice wait'!1'; zplugin light greymd/tmux-xpanes
zplugin ice wait'!1'; zplugin light mollifier/cd-gitroot

# Load completions
zplugin ice blockf; zplugin light zsh-users/zsh-completions
zplugin ice blockf; zplugin light felixr/docker-zsh-completion

#####################################################################
# Shell StartUp
#####################################################################
# Start tmux
[[ -z "$TMUX" && ! -z "$PS1" ]] && exec tmux

#if (which zprof > /dev/null) ;then
#  zprof | less
#fi

