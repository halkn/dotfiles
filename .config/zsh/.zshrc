
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
if [ ! -d ${ZINIT[HOME_DIR]} ]; then
  mkdir -p ${ZINIT[HOME_DIR]}
  git clone https://github.com/zdharma/zinit ${ZINIT[BIN_DIR]}
fi

# Initialize
source ${ZINIT[HOME_DIR]}/bin/zinit.zsh
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

## load plugins
zinit ice wait"0" blockf
zinit light zsh-users/zsh-completions

zinit ice wait"0" atload"_zsh_autosuggest_start"
zinit light zsh-users/zsh-autosuggestions

zinit ice wait"0" atinit"zpcompinit; zpcdreplay"
zinit light zdharma/fast-syntax-highlighting

# prompt
zinit ice pick"async.zsh" src"pure.zsh"
zinit light sindresorhus/pure

# add complection
zinit ice as"completion"
zinit snippet https://github.com/docker/cli/blob/master/contrib/completion/zsh/_docker

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

# cd
alias ..='cd ..'

# zsh
alias zs="source $ZDOTDIR/.zshrc"
alias zb='for i in $(seq 1 10); do time zsh -i -c exit; done'

# vim
alias vi="vim"
alias v.="ls -1a | fzf | xargs -o vim"
alias vv="fd --type f --hidden | fzf | xargs -o vim"
alias vb='for i in $(seq 1 10); do vim --startuptime ~/vim.log -c q; done && grep editing ~/vim.log && rm ~/vim.log'

# dotfiles
alias dot="cd $HOME/.dotfiles && $EDITOR"

# cat to bat
if type bat > /dev/null 2>&1; then
  alias cat="bat"
  alias less="bat"
fi

# lazygit
if type lazygit > /dev/null 2>&1; then
  alias lg="lazygit"
fi

# exit
alias :q="exit"

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

# !!!!!!!!!!!!!!!!!!!!
# cd extension
# !!!!!!!!!!!!!!!!!!!!

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
  dir=$(ghq list > /dev/null | fzf +m) && cd $(ghq root)/$dir
}
alias dev=fuzzy-ghq-list
alias repo=fuzzy-ghq-list

# !!!!!!!!!!!!!!!!!!!!
# git extension
# !!!!!!!!!!!!!!!!!!!!

# Function to judgement if it is git repository.
function is_inside_repo {
  git rev-parse --is-inside-work-tree &>/dev/null
  return $?
}

# gl - git log show with fzf
gl() {
  is_inside_repo || return 1
  local filter
  if [ -n $@ ] && [ -f $@ ]; then
    filter="-- $@"
  fi

  git log \
    --graph \
    --color=always \
    --abbrev=7 \
    --format='%C(auto)%h%d %an %C(blue)%s %C(yellow)%cr' $@ |
  fzf \
    --ansi \
    --exit-0 \
    --height 80% \
    --no-sort \
    --reverse \
    --tiebreak=index \
    --preview "f() { 
        set -- \$(echo -- \$@ | grep -o '[a-f0-9]\{7\}');
        [ \$# -eq 0 ] || git show --color=always \$1 $filter | diff-so-fancy;
      }; f {}" \
    --preview-window=right:60% \
    --bind "ctrl-f:preview-page-down,ctrl-b:preview-page-up" \
    --bind "ctrl-o:toggle-preview" \
    --bind "q:abort" \
    --bind "ctrl-m:execute:
      (grep -o '[a-f0-9]\{7\}' | head -1 |
      xargs -I % sh -c 'git show --color=always % ') << 'FZF-EOF'
      {}
      FZF-EOF"
}

# gs - git status browser
gs() {
  is_inside_repo || return 1
  local out key n files
  while out=$(
    git -c color.status=always -c status.relativePaths=true status --short |
    fzf \
      --ansi \
      --multi \
      --exit-0 \
      --height='80%' \
      --preview "git diff --color=always -- {-1} | diff-so-fancy " \
      --preview-window='right:60%' \
      --expect=ctrl-m,ctrl-d,ctrl-v,ctrl-p,space \
      --bind "ctrl-f:preview-page-down,ctrl-b:preview-page-up" \
      --bind "ctrl-o:toggle-preview" \
      --bind "q:abort"
  ); do
    key=$(head -1 <<< "$out")
    n=$[$(wc -l <<< "$out") - 1]
    files=(`echo $(tail "-$n" <<< "$out" | awk '{print $2}')`)
    state=(`echo $(tail "-$n" <<< "$out" | cut -b 1-1)`)
    if [ "$key" = ctrl-m ]; then
      if [ -z "$state" -o "$state" = "?" ]; then
        git add $files
      else
        git reset -q HEAD $files
      fi
    elif [ "$key" = ctrl-d ]; then
      git difftool $files
    elif [ "$key" = ctrl-v ]; then
      vim $files
    elif [ "$key" = ctrl-p ]; then
      git push
    elif [ "$key" = space ]; then
      tmux split-pane -v && tmux send-keys 'git commit ; exit' C-m
    fi
  done
}

# !!!!!!!!!!!!!!!!!!!!
# homebrew
# !!!!!!!!!!!!!!!!!!!!
# Delete (one or multiple) selected application(s)
# mnemonic [B]rew [U]ninstall [A]pplication
bua() {
  local uninst=$(brew leaves | fzf -m)

  if [[ $uninst ]]; then
    for prog in $(echo $uninst);
    do; brew uninstall $prog; done;
  fi
}

# !!!!!!!!!!!!!!!!!!!!
# gcloud
# !!!!!!!!!!!!!!!!!!!!
# Manage GKE container cluster
# [g]cloud [c]ontainer cluster
gc() {
  local out cluster key n
  out=$(
    gcloud container clusters list |
    fzf \
      --ansi \
      --multi \
      --exit-0 \
      --preview "gcloud container clusters describe {1} | bat -l yml" \
      --expect=ctrl-m,ctrl-d,ctrl-y \
      --bind "ctrl-f:preview-page-down,ctrl-b:preview-page-up" \
      --bind "ctrl-o:toggle-preview" \
      --bind "q:abort" \
  )
  key=$(head -1 <<< "$out")
  n=$[$(wc -l <<< "$out") - 1]
  cluster=(`echo $(tail "-$n" <<< "$out" | awk '{print $1}')`)
  if [ "$key" = ctrl-m ]; then
    gcloud container clusters describe "$cluster" | bat -l yml
  elif [ "$key" = ctrl-d ]; then
    gcloud container clusters delete "$cluster"
  elif [ "$key" = ctrl-y ]; then
    echo -n "$cluster" | pbcopy && echo "cluster name [$cluster] copied to clipboard." 
  fi
}

# !!!!!!!!!!!!!!!!!!!!
# Others
# !!!!!!!!!!!!!!!!!!!!

# fo - Open a file with fuzzy find.
fo() {
  local file
  file=$(fzf) && open "$file"
}

# fh - repeat history.
fh() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed 's/ *[0-9]* *//')
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

# [f]uzzy [rm] command
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

# gmod - Change GO111MODULE interactively.
gmod() {
  echo "!!!!! Current GO111MODULE is" $GO111MODULE "!!!!!"
  local GOMOD=$(echo "on\noff\nauto" | fzf +m)
  if [ -n "${GOMOD}" ]; then
    export GO111MODULE=${GOMOD}
  fi
  echo "!!!!! Change  GO111MODULE is" $GO111MODULE "!!!!!"
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

#####################################################################
# Shell StartUp
#####################################################################
# Load local script
[[ -f ${HOME}/.local.zshrc ]] && source ${HOME}/.local.zshrc
# Start tmux
[[ -z "$TMUX" && ! -z "$PS1" ]] && exec tmux -f "$XDG_CONFIG_HOME"/tmux/tmux.conf

#if (which zprof > /dev/null) ;then
#  zprof | less
#fi

