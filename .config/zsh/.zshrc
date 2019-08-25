
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
stty -ixon

#####################################################################
# zplugin
#####################################################################
# Customizing Paths
declare -A ZPLGM
ZPLGM[HOME_DIR]=${XDG_DATA_HOME:-$HOME/.local/share}/zplugin
ZPLGM[BIN_DIR]=${ZPLGM[HOME_DIR]}/bin
ZPLGM[PLUGINS_DIR]=${ZPLGM[HOME_DIR]}/plugins
ZPLGM[COMPLETIONS_DIR]=${ZPLGM[HOME_DIR]}/completions
ZPLGM[SNIPPETS_DIR]=${ZPLGM[HOME_DIR]}/snippets
ZPLGM[SERVICES_DIR]=${ZPLGM[HOME_DIR]}/services
ZPLGM[ZCOMPDUMP_PATH]=$XDG_CACHE_HOME/zsh/.zcompdump

# Instaling zplugin
if [ ! -d ${ZPLGM[HOME_DIR]} ]; then
  mkdir -p ${ZPLGM[HOME_DIR]}
  git clone https://github.com/zdharma/zplugin ${ZPLGM[BIN_DIR]}
fi

# Initialize
source ${ZPLGM[HOME_DIR]}/bin/zplugin.zsh
autoload -Uz _zplugin
(( ${+_comps} )) && _comps[zplugin]=_zplugin

## load plugins
zplugin ice wait"0" blockf
zplugin light zsh-users/zsh-completions

zplugin ice wait"0" atload"_zsh_autosuggest_start"
zplugin light zsh-users/zsh-autosuggestions

zplugin ice wait"0" atinit"zpcompinit; zpcdreplay"
zplugin light zdharma/fast-syntax-highlighting

# prompt
zplugin ice pick"async.zsh" src"pure.zsh"
zplugin light sindresorhus/pure

zplugin ice as"completion"
zplugin snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

#####################################################################
# Keybind
#####################################################################
# vim key bind
bindkey -v

# insert mode keybind (like emacs)
bindkey -M viins '^A'  beginning-of-line
bindkey -M viins '^B'  backward-char
bindkey -M viins '^E'  end-of-line
bindkey -M viins '^F'  forward-char
bindkey -M viins '^H'  backward-delete-char

#####################################################################
# completion
#####################################################################
# load command completion function
autoload -Uz compinit
# load compinit
compinit -d $XDG_CACHE_HOME/zsh/.zcompdump

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
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME}/.zcompcache"

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
if type exa > /dev/null 2>&1; then
    alias ls="exa"
    alias ll="ls -l --time-style=long-iso"
    alias la="exa -la --git --time-style=long-iso"
    alias tree="exa -laT --time-style=long-iso --git-ignore --ignore-glob='.git|.svn'"
else
    case ${OSTYPE} in
        darwin* )
            if [[ -x `which gls` ]]; then
                alias ls="gls --color=auto"
            else
                alias ls="ls -G"
            fi
            ;;
        linux* )
            alias ls="ls --color=auto"
            ;;
    esac
    alias ll="ls -lhF"
    alias la="ls -lhAF"
fi

#####################################################################
# alias
#####################################################################
# nocorrect command
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'

# human readable for du and df
alias du="du -h"
alias df="df -h"

# cat to bat
if type bat > /dev/null 2>&1; then
    alias cat="bat"
    alias less="bat"
    export GIT_PAGER="bat"
fi

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
setopt print_eight_bit
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

# fo - Open a file with fuzzy find.
fo() {
    local file
    file=$(fzf) && open "$file"
}

# fda - including hidden directories
fda() {
  local dir
  dir=$(fd --hidden --type d --follow --exclude "{.git,.svn}" 2> /dev/null | fzf +m) && cd "$dir"

}

# fdr - cd to selected parent directory
fdr() {
    get_parent_dirs() {
        local dpath
        for dir in $(echo ${PWD} | tr "/" " " | sed 's/^[ \t]*//')
        do
            dpath+="/"$dir && echo "${dpath}"
        done
    }
    local DIR="$( get_parent_dirs |
        fzf --reverse --preview '
            __cd_nxt="$(echo {})";
            __cd_path="$(echo ${__cd_nxt} | sed "s;//;/;")";
            echo $__cd_path;
            echo;
            ls -aF "${__cd_path}";
    ')"
  cd "${DIR}"
}

# fh - repeat history
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}

# interactive cd
function cd() {
    if [[ "$#" != 0 ]]; then
        builtin cd "$@";
        return
    fi
    while true; do
        local lsd=$(ls -aaF | grep '/$' | sed 's;/$;;')
        local dir="$(printf '%s\n' "${lsd[@]}" |
            fzf --reverse --preview '
                __cd_nxt="$(echo {})";
                __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
                echo $__cd_path;
                echo;
                ls -aF "${__cd_path}";
        ')"
        [[ ${#dir} != 0 ]] || return 0
        builtin cd "$dir" &> /dev/null
    done
}

# interactice ssh
function ssh() {
    if [[ "$#" != 0 ]];then
        /usr/bin/ssh "$@";
        return
    fi
    local host=$(rg '^Host' ~/.ssh/config | awk '{print $2}' | fzf )
    [[ ${#host} != 0 ]] || return 0
    /usr/bin/ssh "$host"
}

# fshow - git commit browser
fshow() {
  git log --graph --color=always \
      --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
  fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
      --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always %') << 'FZF-EOF'
                {}
FZF-EOF"
}


fadd() {
  local out q n addfiles
  while out=$(
      git status --short |
      awk '{if (substr($0,2,1) !~ / /) print $2}' |
      fzf-tmux --multi --exit-0 --expect=ctrl-d); do
    q=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    addfiles=(`echo $(tail "-$n" <<< "$out")`)
    [[ -z "$addfiles" ]] && continue
    if [ "$q" = ctrl-d ]; then
      git diff --color=always $addfiles
    else
      git add $addfiles
    fi
  done
}

#####################################################################
# Shell StartUp
#####################################################################
# Start tmux
[[ -z "$TMUX" && ! -z "$PS1" ]] && exec tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf

#if (which zprof > /dev/null) ;then
#  zprof | less
#fi

