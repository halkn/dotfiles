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
if [ -f $ZPLUGINDIR/zsh-autosuggestions/zsh-autosuggestions.zsh ]; then
  source $ZPLUGINDIR/zsh-autosuggestions/zsh-autosuggestions.zsh
fi 
if [ -f $ZPLUGINDIR/zsh-syntax-highlighting//zsh-syntax-highlighting.zsh ]; then
  source $ZPLUGINDIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
fi 

#####################################################################
# for devbox
#####################################################################
if type devbox > /dev/null 2>&1; then
  eval "$(devbox global shellenv)"
fi

#####################################################################
# nvim
#####################################################################
if type nvim > /dev/null 2>&1; then
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

#####################################################################
# uv (for python)
#####################################################################
# for uv
if type uv > /dev/null 2>&1; then
  eval "$(uv generate-shell-completion zsh)"
fi

#####################################################################
# fzf
#####################################################################
if type fzf > /dev/null 2>&1; then
  source <(fzf --zsh)

  # fh - repeat history
  fh() {
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
  }

  # fcd - interactive change directory
  alias fcd='cd $(fd --type d --hidden | fzf \
    --preview "eza -lah --color=always --icons {} && echo && eza --tree --level=2 --color=always --icons {}" \
    --preview-window=right:60% \
    --bind "ctrl-/:toggle-preview")'

  # gb - interactive git switch
  fzf-git-branch() {
    local branches branch
 
    branches=$(git branch --all --color=always --format='%(refname:short)|%(authorname)|%(committerdate:relative)' | grep -v HEAD) &&
    branch=$(echo "$branches" |
      column -t -s '|' |
      fzf --ansi \
        --preview-window=right:70% \
        --preview '
          branch=$(echo {} | awk "{print \$1}" | sed "s#remotes/[^/]*/##")
          echo "=== Branch: $branch ==="
          echo
          git log --oneline --graph --date=short --color=always --pretty="format:%C(auto)%cd %h%d %s" $branch | head -50
          echo
          echo "=== Recent commits ==="
          git log --color=always --pretty=format:"%C(yellow)%h %C(blue)%ad %C(green)%an%C(reset)%n%s%n" --date=short $branch | head -20
        ' \
        --bind "ctrl-/:toggle-preview" \
        --bind "ctrl-u:preview-page-up,ctrl-d:preview-page-down" \
        --bind "ctrl-o:execute(git log --oneline --graph --color=always {1} | delta)" \
        --header "Enter: checkout / Ctrl-/: toggle preview / Ctrl-O: full log") &&
 
    branch=$(echo "$branch" | awk '{print $1}' | sed "s#remotes/[^/]*/##")
 
    if [ -n "$branch" ]; then
      git switch "$branch"
    fi
  }
  alias gb='fzf-git-branch'
fi

#####################################################################
# ghq + fzf
#####################################################################
if type ghq > /dev/null 2>&1; then
  ghq-cd () {
    local repo=$(ghq list | fzf)
    if [ -n "$repo" ]; then
      repo=$(ghq list --full-path --exact $repo)
      cd ${repo} && ls -la
    fi
  }
  alias dev='ghq-cd'
fi

#####################################################################
# prompt
#####################################################################
if type starship > /dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi

