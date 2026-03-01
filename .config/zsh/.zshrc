#####################################################################
# auto zcompile
#####################################################################
if [ ! -f $ZDOTDIR/.zshrc.zwc -o $ZDOTDIR/.zshrc -nt $ZDOTDIR/.zshrc.zwc ]; then
  zcompile $ZDOTDIR/.zshrc
fi

#####################################################################
# options
#####################################################################
# Ignore Ctrl-D logout from zsh
setopt ignore_eof
# Disable flow control
setopt no_flow_control
# beep off
setopt no_beep

# history
export HISTFILE=$XDG_DATA_HOME/zsh/history
export HISTSIZE=10000
export SAVEHIST=10000
# Ignore all duplicates in history (including non-consecutive)
setopt hist_ignore_all_dups
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
# prevent duplicate directories in directory stack
setopt pushd_ignore_dups

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
# To treat '#' as comment in command line
setopt interactive_comments

#####################################################################
# Keybind
#####################################################################
# emacs key bind
bindkey -e

#####################################################################
# plugins
#####################################################################
source $ZDOTDIR/plugins.zsh

#####################################################################
# completion
#####################################################################
# load command completion function
autoload -Uz compinit
# load compinit with XDG cache location for dump file
# skip regeneration if dump file is less than 24 hours old
if [[ -n $XDG_CACHE_HOME/zsh/.zcompdump(#qN.mh+24) ]]; then
  compinit -d $XDG_CACHE_HOME/zsh/.zcompdump
else
  compinit -C -d $XDG_CACHE_HOME/zsh/.zcompdump
fi

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
alias ltr='ls -lhFtr'

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
# mise
#####################################################################
if command -v mise > /dev/null 2>&1; then
  eval "$(mise activate zsh --shims)"
fi

#####################################################################
# alt commands
#####################################################################
# eza
if command -v eza > /dev/null 2>&1; then
  alias ls='eza --group-directories-first'
  alias ll='eza -l --group-directories-first --time-style=long-iso --git'
  alias la='eza -la --group-directories-first --time-style=long-iso --git'
  alias ltr='eza -l --sort=modified --reverse'
  alias lst='eza -l --sort=modified'
  alias tree='eza --tree --group-directories-first --time-style=long-iso -I .git'
fi

#####################################################################
# nvim
#####################################################################
if command -v nvim > /dev/null 2>&1; then
  export EDITOR=nvim
  export MANPAGER='nvim +Man!'
  alias vim=nvim
  alias vimdiff='nvim -d'
fi

#####################################################################
# uv (for python)
#####################################################################
if command -v uv > /dev/null 2>&1; then
  _uv_comp=$XDG_CACHE_HOME/zsh/uv_completion.zsh
  if [[ ! -f $_uv_comp ]]; then
    mkdir -p ${_uv_comp:h}
    uv generate-shell-completion zsh > $_uv_comp
  fi
  source $_uv_comp
fi

#####################################################################
# fzf
#####################################################################
if command -v fzf > /dev/null 2>&1; then
  source <(fzf --zsh)

  # fh - repeat history
  fh() {
    print -z $(fc -l 1 | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
  }

  # fcd - interactive change directory
  if command -v fd > /dev/null 2>&1; then
    alias fcd='cd $(fd --type d --hidden | fzf \
      --preview "eza -lah --color=always --icons {} && echo && eza --tree --level=2 --color=always --icons {}" \
      --preview-window=right:60% \
      --bind "ctrl-/:toggle-preview")'
  fi

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
if command -v ghq > /dev/null 2>&1; then
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
if command -v starship > /dev/null 2>&1; then
  export STARSHIP_CONFIG=$XDG_CONFIG_HOME/starship/starship.toml
  export STARSHIP_CACHE=$XDG_CACHE_HOME/starship/cache
  eval "$(starship init zsh)"
fi
