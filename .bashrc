# ---------------------------------------------------------------------------
# Init
# ---------------------------------------------------------------------------
# If not running interactively, don't do anything
case $- in
    *i*) ;;
      *) return;;
esac

# ---------------------------------------------------------------------------
# options
# ---------------------------------------------------------------------------
# HISTORY
export HISTFILE="$XDG_DATA_HOME/bash/history"
HISTCONTROL=ignoreboth
HISTSIZE=10000
HISTFILESIZE=10000
shopt -s histappend

# ---------------------------------------------------------------------------
# Extension
# ---------------------------------------------------------------------------

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# prompt
[[ -f "$XDG_DATA_HOME/gitstatus/gitstatus.prompt.sh" ]] && . $XDG_DATA_HOME/gitstatus/gitstatus.prompt.sh 

# bash_complection
[[ -f $BREW_PREFIX/etc/profile.d/bash_completion.sh ]] && . $BREW_PREFIX/etc/profile.d/bash_completion.sh

# fzf completion
[[ -f $BREW_PREFIX/opt/fzf/shell/completion.bash ]] && . $BREW_PREFIX/opt/fzf/shell/completion.bash

# ---------------------------------------------------------------------------
# alias
# ---------------------------------------------------------------------------
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
      if [[ -x $(which gls) ]]; then
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

# safety command
alias mv='mv -i'
alias cp='cp -i'
alias rm='rm -i'

# human readable for du and df
alias du="du -h"
alias df="df -h"

# vim
alias vi="vim"
alias v.="ls -1a | fzf | xargs -o vim"
alias v="fd --type f --hidden | fzf --height 80% --preview 'bat --color=always {}'| xargs -o vim"
alias vb='for i in $(seq 1 10); do vim --startuptime ~/vim.log -c q; done && grep editing ~/vim.log && rm -f ~/vim.log'
alias vl='rm -f vim.log && vim --startuptime vim.log  -c :q && bat vim.log && rm -f vim.log'

# cat to bat
if type bat > /dev/null 2>&1; then
  alias cat="bat"
  alias less="bat"
fi

# useful
alias ..='cd ..'
alias dot='cd $HOME/.dotfiles && $EDITOR'
alias path='echo $PATH | tr ":" "\n"'
alias bs="source ~/.bashrc"

# exit
alias :q="exit"

# git
alias gp='git pull'
alias gs='vim -c FzfGStatus'
alias gl='vim -c FzfCommits'

# ---------------------------------------------------------------------------
# function
# ---------------------------------------------------------------------------

### improve command ---------------------------------------------------------

# cd - interactive cd
function cd() {
  if [[ "$#" != 0 ]]; then
    builtin cd "$@" || return
    return
  fi
  while true; do
    local lsd dir
    # shellcheck disable=SC2010
    lsd=$(ls -aaF1 | grep '/$' | sed 's;/$;;')
    # shellcheck disable=SC2016
    dir="$(printf '%s\n' "${lsd[@]}" |
      fzf --reverse --preview '
        __cd_nxt="$(echo {})";
        __cd_path="$(echo $(pwd)/${__cd_nxt} | sed "s;//;/;")";
        echo $__cd_path;
        echo;
        ls -aF "${__cd_path}";
    ')"
    [[ ${#dir} != 0 ]] || return 0
    builtin cd "$dir" &> /dev/null || return
  done
}

# ssh - interactice ssh.
function ssh() {
  if [[ "$#" != 0 ]];then
    /usr/bin/ssh "$@";
    return
  fi
  local host
  host=$(rg '^Host' ~/.ssh/config | awk '{print $2}' | fzf )
  [[ ${#host} != 0 ]] || return 0
  /usr/bin/ssh "$host"
}

# man - man wich color
man() {
  env \
    LESS_TERMCAP_mb="$(printf "\e[1;33m")" \
    LESS_TERMCAP_md="$(printf "\e[1;36m")" \
    LESS_TERMCAP_me="$(printf "\e[0m")" \
    LESS_TERMCAP_se="$(printf "\e[0m")" \
    LESS_TERMCAP_so="$(printf "\e[1;44;33m")" \
    LESS_TERMCAP_ue="$(printf "\e[0m")" \
    LESS_TERMCAP_us="$(printf "\e[1;32m")" \
    man "$@"
}

### chance directory --------------------------------------------------------

# fda - including hidden directories
fda() {
  local dir
  dir=$(fd --hidden --type d --follow --exclude "{.git,.svn}" 2> /dev/null | fzf +m) 
  cd "$dir" || return
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
  local DIR
  # shellcheck disable=SC2016
  DIR="$( get_parent_dirs |
    fzf --reverse --preview '
      __cd_nxt="$(echo {})";
      __cd_path="$(echo ${__cd_nxt} | sed "s;//;/;")";
      echo $__cd_path;
      echo;
      ls -aF "${__cd_path}";
  ')"
  cd "${DIR}" || return
}
alias ...=fdr

### utiltiy command with fzf ------------------------------------------------

# fo - Open a file with fuzzy find.
fo() {
  local file
  file=$(fzf) && open "$file"
}

# frm - [f]uzzy [rm] command
function frm() {
  getopts 'r' opts
  local file fcmd rcmd
  if [ "$opts" != "r"  ]; then
    fcmd="fd --hidden -d 1 --type f"
    rcmd="rm -f"
  else
    fcmd="fd --hidden -d 1"
    rcmd="rm -fr"
  fi

  file=$($fcmd | fzf -m --preview 'ls -l {}' --preview-window up:1)
  while read -r line; do
    $rcmd $line
  done < <(echo "$file")
  echo "!! Print list directory contents after remove files !!" ; ls -la
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

### homebrew ----------------------------------------------------------------

# bua [B]rew [U]ninstall [A]pplication
bua() {
  local uninst
  uninst=$(brew leaves | fzf -m)
  if [[ $uninst ]]; then
    for prog in $uninst;do 
      brew uninstall $prog
    done;
  fi
}

### ghq ---------------------------------------------------------------------

# fuzzy-ghq-list - cd to development directory in ghq list.
fuzzy-ghq-list() {
  local dir
  dir=$(ghq list | fzf +m --preview "exa -T $(ghq root)/{}")
  if [[ $dir ]]; then
    cd "$(ghq root)/$dir" || return
  fi
}
alias dev=fuzzy-ghq-list

### golang ------------------------------------------------------------------

# gmod - Change GO111MODULE interactively.
gmod() {
  echo "!!!!! Current GO111MODULE is" $GO111MODULE "!!!!!"
  local GOMOD
  GOMOD=$(echo -ne "on\noff\nauto" | fzf +m)
  if [ -n "${GOMOD}" ]; then
    export GO111MODULE=${GOMOD}
  fi
  echo "!!!!! Change  GO111MODULE is" $GO111MODULE "!!!!!"
}

# ---------------------------------------------------------------------------
# key bind
# ---------------------------------------------------------------------------
# C-r : fuzzy find for command history.
bind '"\C-r": "\C-x1\e^\er"'
bind -x '"\C-x1": __fzf_history';

__fzf_history(){
  __ehc "$(history | fzf --tac --tiebreak=index | perl -ne 'm/^\s*([0-9]+)/ and print "!$1"')"
}

__ehc(){
if
  [[ -n $1 ]]
then
  bind '"\er": redraw-current-line'
  bind '"\e^": magic-space'
  READLINE_LINE=${READLINE_LINE:+${READLINE_LINE:0:READLINE_POINT}}${1}${READLINE_LINE:+${READLINE_LINE:READLINE_POINT}}
  READLINE_POINT=$(( READLINE_POINT + ${#1} ))
else
  bind '"\er":'
  bind '"\e^":'
fi
}

