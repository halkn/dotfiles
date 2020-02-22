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
[[ -f "$XDG_DATA_HOME/gitstatus/gitstatus.prompt.sh" ]] && source $XDG_DATA_HOME/gitstatus/gitstatus.prompt.sh 

# bash_complection
[[ -f /usr/share/bash-completion/bash_completion ]] && . /usr/share/bash-completion/bash_completion
[[ -f /usr/local/etc/bash_completion ]] && . /usr/local/etc/bash_completion

# fzf completion
[[ -f /usr/local/opt/fzf/shell/completion.bash ]] && source /usr/local/opt/fzf/shell/completion.bash

# ---------------------------------------------------------------------------
# alias
# ---------------------------------------------------------------------------
# ls
if type exa > /dev/null 2>&1; then
  alias ls="exa"
  alias ll="ls -l --time-style=long-iso"
  alias la="exa -la --git --time-style=long-iso"
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
alias vv="fd --type f --hidden | fzf --height 80% --preview 'bat --color=always {}'| xargs -o vim"
alias vb='for i in $(seq 1 10); do vim --startuptime ~/vim.log -c q; done && grep editing ~/vim.log && rm ~/vim.log'

# cat to bat
if type bat > /dev/null 2>&1; then
  alias cat="bat"
  alias less="bat"
fi

# useful
alias ..='cd ..'
alias dot="cd $HOME/.dotfiles && $EDITOR"
alias path="echo $PATH | tr ':' '\n'"
alias bs="source ~/.bashrc"

# exit
alias :q="exit"

# ---------------------------------------------------------------------------
# function
# ---------------------------------------------------------------------------

### chance directory --------------------------------------------------------
# cd - interactive cd
function cd() {
  if [[ "$#" != 0 ]]; then
    builtin cd "$@";
    return
  fi
  while true; do
    local lsd=$(ls -aaF1 | grep '/$' | sed 's;/$;;')
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
alias ...=fdr

# fuzzy-ghq-list - cd to development directory in ghq list.
fuzzy-ghq-list() {
  local dir
  dir=$(ghq list | fzf +m --preview "exa -T $(ghq root)/{}") && cd $(ghq root)/$dir
}
alias dev=fuzzy-ghq-list

### homebrew ----------------------------------------------------------------
# bua [B]rew [U]ninstall [A]pplication
bua() {
  local uninst=$(brew leaves | fzf -m)

  if [[ $uninst ]]; then
    for prog in $(echo $uninst);do 
      brew uninstall $prog
    done;
  fi
}

### Other -------------------------------------------------------------------
# fo - Open a file with fuzzy find.
fo() {
  local file
  file=$(fzf) && open "$file"
}

# v - open files viminfo by vim
v() {
  local file=$(
    grep '^>' $XDG_CACHE_HOME/vim/viminfo |
    cut -c3- |
    while read line; do
      [ -f "${line/\~/$HOME}"  ] && echo "$line"
    done |
    fzf \
      -q "$*" \
      --height='80%' \
      --preview "echo {} | sed 's@\~@$HOME@g' | xargs bat --color=always" \
      --bind "ctrl-f:preview-page-down,ctrl-b:preview-page-up" \
      --bind "ctrl-o:toggle-preview" \
      --preview-window='right:60%'
  ) && \
    [[ -n "${file}" ]] && \
    cd $(dirname ${file//\~/$HOME} | head -1) && \
    cd $(git rev-parse --show-superproject-working-tree --show-toplevel | head -1) && \
    vim ${file//\~/$HOME}
}

# frm - [f]uzzy [rm] command
frm() {
  local file=$(\ls -1 | fzf -m --preview 'ls -l {}' --preview-window up:1)
	while read line; do
		rm $line
	done < <(echo "$file")
	echo "!! Print list directory contents after remove files !!" ; ls -la
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

### golang ------------------------------------------------------------------

# gmod - Change GO111MODULE interactively.
gmod() {
  echo "!!!!! Current GO111MODULE is" $GO111MODULE "!!!!!"
  local GOMOD=$(echo "on\noff\nauto" | fzf +m)
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
  __ehc $(history | fzf --tac --tiebreak=index | perl -ne 'm/^\s*([0-9]+)/ and print "!$1"')
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

# ---------------------------------------------------------------------------
# startup
# ---------------------------------------------------------------------------
[[ -z "$TMUX" && ! -z "$PS1" ]] && exec tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf
