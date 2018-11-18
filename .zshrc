
#####################################################################
# init
#####################################################################
# zmodload zsh/zprof
if [ ! -f ~/.zshrc.zwc -o ~/.zshrc -nt ~/.zshrc.zwc ]; then
    zcompile ~/.zshrc
fi

#####################################################################
# zplug
#####################################################################
# init
source ~/.zplug/init.zsh

# self-manage
zplug 'zplug/zplug', hook-build:'zplug --self-manage'
# theme
zplug "mafredri/zsh-async"
zplug "sindresorhus/pure"
# history
zplug "zsh-users/zsh-history-substring-search", defer:3
# highlight
zplug "zsh-users/zsh-syntax-highlighting", defer:2
# completions
zplug "zsh-users/zsh-autosuggestions"
zplug "zsh-users/zsh-completions"
# interactive filter
zplug "junegunn/fzf-bin", as:command, from:gh-r, rename-to:fzf

## Install plugins if there are plugins that have not been installed
if ! zplug check --verbose; then
  printf "Install? [y/N]: "
    if read -q; then
        echo; zplug install
    fi
fi

# Then, source plugins and add commands to $PATH
zplug load

if (which zprof > /dev/null) ;then
  zprof | less
fi

# zsh起動時にtmux起動
[[ -z "$TMUX" && ! -z "$PS1" ]] && exec tmux

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

# 補完侯補をメニューから選択する。
# select=2: 補完候補を一覧から選択する。
#           ただし、補完候補が2つ以上なければすぐに補完する。
zstyle ':completion:*:default' menu select=2

# 補完候補にLS_COLORSと同じ色を付ける。 
# zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*' list-colors $LSCOLORS

zstyle ':completion:*' group-name ''
zstyle ':completion:*:messages' format '%d'
zstyle ':completion:*:descriptions' format '%d'
zstyle ':completion:*:options' verbose yes
zstyle ':completion:*:values' verbose yes
zstyle ':completion:*:options' prefix-needed yes
#####################################################################
# alias
#####################################################################
# nocorrect command
alias mv='nocorrect mv'
alias cp='nocorrect cp'
alias mkdir='nocorrect mkdir'

# Util
alias ls="ls -G"
alias ll="ls -lh"
alias la="ll -a"
alias vim="nvim"

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
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt hist_ignore_dups
setopt share_history

