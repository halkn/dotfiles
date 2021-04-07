# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.config/zsh/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
# if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
#   source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
# fi

#####################################################################
# Start tmux
#####################################################################
[[ -z "$TMUX" && ! -z "$PS1" ]] && exec tmux

#####################################################################
# auto zcompile
#####################################################################
if [ ! -f $ZDOTDIR/.zshrc.zwc -o $ZDOTDIR/.zshrc -nt $ZDOTDIR/.zshrc.zwc ]; then
  zcompile $ZDOTDIR/.zshrc
fi

#####################################################################
# General Setting
#####################################################################
umask 022
stty -ixon

#####################################################################
# zinit
#####################################################################
# Customizing Paths
declare -A ZINIT
ZINIT[HOME_DIR]=${XDG_DATA_HOME:-$HOME/.local/share}/zinit
ZINIT[BIN_DIR]=${ZINIT[HOME_DIR]}/bin
ZINIT[PLUGINS_DIR]=${ZINIT[HOME_DIR]}/plugins
ZINIT[COMPLETIONS_DIR]=${ZINIT[HOME_DIR]}/completions
ZINIT[SNIPPETS_DIR]=${ZINIT[HOME_DIR]}/snippets
ZINIT[SERVICES_DIR]=${ZINIT[HOME_DIR]}/services
ZINIT[ZCOMPDUMP_PATH]=$XDG_CACHE_HOME/zsh/.zcompdump

# Instaling zinit
if [ ! -d ${ZINIT[BIN_DIR]} ]; then
  mkdir -p ${ZINIT[HOME_DIR]}
  git clone https://github.com/zdharma/zinit ${ZINIT[BIN_DIR]}
fi

# Initialize
source ${ZINIT[HOME_DIR]}/bin/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# load plugins
zinit wait lucid light-mode for \
  atinit"zicompinit; zicdreplay" \
    zdharma/fast-syntax-highlighting \
  atload"_zsh_autosuggest_start" \
    zsh-users/zsh-autosuggestions \
  blockf atpull'zinit creinstall -q .' \
    zsh-users/zsh-completions

# zinit wait'0' lucid \
#   from'gh-r' ver'nightly' as'program' pick'nvim*/bin/nvim' \
#   atclone'echo "" > ._zinit/is_release' \
#   atpull'%atclone' \
#   run-atpull \
#   light-mode for @neovim/neovim

# prompt
zinit ice depth=1; zinit light romkatv/powerlevel10k

# complection
zinit ice as"completion"
zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

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
# gcloud
#####################################################################
[[ -f ${HOME}/google-cloud-sdk/path.zsh.inc ]] && source ${HOME}/google-cloud-sdk/path.zsh.inc
[[ -f ${HOME}/google-cloud-sdk/completion.zsh.inc ]] && source ${HOME}/google-cloud-sdk/completion.zsh.inc
[[ -f ${XDG_CONFIG_HOME}/zsh/rc.d/gcloud.zsh ]] && source ${XDG_CONFIG_HOME}/zsh/rc.d/gcloud.zsh

#####################################################################
# alias
#####################################################################
# ls
if type exa > /dev/null 2>&1; then
  alias ls="exa --sort=type"
  alias ll="ls -l --time-style=long-iso"
  alias la="ls -la --git --time-style=long-iso"
  alias ltr="ll --sort=modified"
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
  alias ltr="ll -tr"
fi

# nocorrect command
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'

# human readable for du and df
alias du="du -h"
alias df="df -h"

# cd
alias ..='cd ..'

# zsh
alias zs="source $ZDOTDIR/.zshrc"
alias zb='for i in $(seq 1 10); do time zsh -i -c exit; done'

# vim
alias vi=$EDITOR
alias v.="find . -maxdepth 1 -type f | fzf | xargs -o $EDITOR"
alias v="fd --type f --hidden | fzf --height 80% --preview 'bat --color=always {}'| xargs -o $EDITOR"

# dotfiles
alias dot="cd $HOME/.dotfiles && $EDITOR"

# cat to bat
if type bat > /dev/null 2>&1; then
  alias cat="bat"
  alias less="bat"
fi

# git
alias gp='git pull'

# etc
alias :q="exit"
alias color='for i in {0..255}; do printf "\x1b[38;5;${i}mcolour${i}\n" ;done'
alias path='echo $PATH | tr ":" "\n"'

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

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# improve command
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# cd - interactive cd
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

# ssh - interactice ssh.
function ssh() {
  if [[ "$#" != 0 ]];then
    /usr/bin/ssh "$@";
    return
  fi
  local host=$(rg '^Host' ~/.ssh/config | awk '{print $2}' | fzf )
  [[ ${#host} != 0 ]] || return 0
  /usr/bin/ssh "$host"
}

# man - man wich color
man() {
    env \
        LESS_TERMCAP_mb=$(printf "\e[1;33m") \
        LESS_TERMCAP_md=$(printf "\e[1;36m") \
        LESS_TERMCAP_me=$(printf "\e[0m") \
        LESS_TERMCAP_se=$(printf "\e[0m") \
        LESS_TERMCAP_so=$(printf "\e[1;44;33m") \
        LESS_TERMCAP_ue=$(printf "\e[0m") \
        LESS_TERMCAP_us=$(printf "\e[1;32m") \
        man "$@"
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# change directory with fzf.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# fda - [F]uzzy Change [D]irectory [A]ll directorys
fda() {
  local dir
  dir=$(fd --hidden --type d --follow --exclude "{.git,.svn}" 2> /dev/null | fzf +m) && cd "$dir"
}

# fdr - [F]uzzy Change [D]irectory [R]everse paternt directorys
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
alias ...=fdr

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# utiltiy command with fzf.
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

# fo - Open a file.
fo() {
  local file
  file=$(fzf) && open "$file"
}

# fh - Searce history.
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
}
zle -N fh
bindkey '^R' fh

# frm - Remove a file.
frm() {
  local -A opthash
  zparseopts -D -A opthash -- d r
  local file fcmd ropt 

  if [[ -n "${opthash[(i)-d]}" ]]; then
    fcmd=$(fd --hidden --type d)
  elif [[ -n "${opthash[(i)-r]}" ]]; then
    fcmd=$(fd --hidden)
  else
    fcmd=$(fd --hidden -d 1)
  fi

  file=$(echo "$fcmd" | fzf -m --preview 'ls -l {}' --preview-window up:1)
  while read -r line; do
    rm -frv $line
  done < <(echo "$file")
}

# fkill - kill processes - list only the ones you can kill.
fkill() {
  local pid 
  if [ "$UID" != "0" ]; then
      pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
  else
      pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
  fi

  if [ "x$pid" != "x" ]
  then
      echo $pid | xargs kill -${1:-9}
  fi
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# git
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# fbr - checkout git branch (including remote branches),
#       sorted by most recent commit, limit 30 last branches.
fbr() {
  local branches branch
  branches=$(git for-each-ref --count=30 --sort=-committerdate refs/heads/ --format="%(refname:short)") &&
  branch=$(echo "$branches" |
           fzf -d $(( 2 + $(wc -l <<< "$branches") )) +m) &&
  git switch "$(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")"
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# homebrew
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Delete (one or multiple) selected application(s)
# mnemonic [B]rew [U]ninstall [A]pplication
bua() {
  local uninst=$(brew leaves | fzf -m)

  if [[ $uninst ]]; then
    for prog in $(echo $uninst);
    do; brew uninstall $prog; done;
  fi
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# ghq
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# fuzzy-ghq-list - cd to development directory in ghq list.
fuzzy-ghq-list() {
  local dir
  dir=$(ghq list > /dev/null | fzf --height 100% --preview="glow $(ghq root)/{}/README.md")
  if [[ ${dir} ]]; then
    cd $(ghq root)/${dir}
  fi
}
alias dev=fuzzy-ghq-list
alias repo=fuzzy-ghq-list
zle -N fuzzy-ghq-list
bindkey '^G' fuzzy-ghq-list


# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# Golang
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# gmod - Change GO111MODULE interactively.
gmod() {
  echo "!!!!! Current GO111MODULE is" $GO111MODULE "!!!!!"
  local GOMOD=$(echo "on\noff\nauto" | fzf +m)
  if [ -n "${GOMOD}" ]; then
    export GO111MODULE=${GOMOD}
  fi
  echo "!!!!! Change  GO111MODULE is" $GO111MODULE "!!!!!"
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# vim
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
vp() {
  local dir base selected
  base="${XDG_DATA_HOME}/vim/pack/minpac/"
  dir=$(fd --type d --max-depth=2 . "${base}" | sed "s@${base}@@")

  selected=$(echo "${dir}" | fzf \
    --height=100% \
    --preview="glow ${base}{}/README.md")
  if [ -n "${selected}" ]; then
    builtin cd "${base}${selected}"
  fi
}

# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# tmux
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
ftpane() {
  local panes current_window current_pane target target_window target_pane
  panes=$(tmux list-panes -s -F '#I:#P - #{pane_current_path} #{pane_current_command}')
  current_pane=$(tmux display-message -p '#I:#P')
  current_window=$(tmux display-message -p '#I')

  target=$(echo "$panes" | grep -v "$current_pane" | fzf +m --reverse --height=100%) || return

  target_window=$(echo $target | awk 'BEGIN{FS=":|-"} {print$1}')
  target_pane=$(echo $target | awk 'BEGIN{FS=":|-"} {print$2}' | cut -c 1)

  if [[ $current_window -eq $target_window ]]; then
    tmux select-pane -t ${target_window}.${target_pane}
  else
    tmux select-pane -t ${target_window}.${target_pane} &&
    tmux select-window -t $target_window
  fi
}


# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# lab
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
fli() {
  local selected
  selected=$(lab issue search |\
      fzf \
      --height=100% \
      --preview="echo {1} | sed 's/#//' | xargs -I@ lab issue show @"\
  )
  if [ -n "${selected}"  ]; then
    echo "${selected}" |\
      awk '{print $1}' |\
      sed 's/#//' |\
      xargs -I@ lab issue show @ |\
      bat --language markdown --paging always --style=plain
  fi
}

#####################################################################
# Load local script
#####################################################################
[[ -f ${HOME}/.local.zshrc ]] && source ${HOME}/.local.zshrc

#if (which zprof > /dev/null) ;then
#  zprof | less
#fi

# To customize prompt, run `p10k configure` or edit ~/.config/zsh/.p10k.zsh.
[[ ! -f ~/.config/zsh/.p10k.zsh ]] || source ~/.config/zsh/.p10k.zsh
