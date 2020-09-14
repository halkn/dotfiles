#####################################################################
# init
#####################################################################
# skip load /etc/z*
setopt no_global_rcs

#####################################################################
# Enviroment Variables
#####################################################################
# common
export LANG=en_US.UTF-8
export EDITOR=nvim
export PAGER=less
export SHELL=zsh

# XDG Base Directory
export XDG_CONFIG_HOME=~/.config
export XDG_DATA_HOME=~/.local/share
export XDG_CACHE_HOME=~/.cache

# zsh
export ZDOTDIR=$XDG_CONFIG_HOME/zsh

# golang
export GOPATH=$XDG_DATA_HOME/go
export GO111MODULE=on

# nodebrew
export NODEBREW_ROOT=$XDG_DATA_HOME/nodebrew

# npm
export NPM_HOME=$XDG_DATA_HOME/npm
export NPM_CONFIG_USERCONFIG=$XDG_CONFIG_HOME/npm/npmrc

# RubyGems
export GEM_HOME="$XDG_DATA_HOME"/gem
export GEM_SPEC_CACHE="$XDG_CACHE_HOME"/gem

# Docker
export DOCKER_CONFIG="$XDG_CONFIG_HOME"/docker

# homebrew
export HOMEBREW_NO_INSTALL_CLEANUP=1

# PATH
typeset -U path
path=(
    /usr/local/go/bin(N-/)
    $GOPATH/bin(N-/)
    $NODEBREW_ROOT/current/bin(N-/)
    $NPM_HOME/bin(N-/)
    $HOME/.local/bin(N-/)
    /usr/local/bin(N-/)
    /usr/bin(N-/)
    /bin(N-/)
    /usr/local/sbin(N-/)
    /usr/sbin(N-/)
    /sbin(N-/)
    $path
)

# less
export LESS='-g -i -M -R -S -W -z-4 -x4'
export LESSHISTFILE=-

# fzf
export FZF_DEFAULT_COMMAND='fd --type file --follow --hidden -E .git -E .svn'
export FZF_DEFAULT_OPTS='--height 50% --layout=reverse --border --preview-window=right:60%'
export FZF_GIT_DEFAULT_OPTS=" \
--ansi \
--height='100%' \
--bind='ctrl-d:preview-page-down' \
--bind='ctrl-u:preview-page-up' \
--bind='alt-k:preview-up' \
--bind='alt-j:preview-down' \
--bind='alt-s:toggle-sort' \
--bind='?:toggle-preview' \
"

# ripgrep
export RIPGREP_CONFIG_PATH=$XDG_CONFIG_HOME/ripgrep/config

# ignore shellcheck
export SHELLCHECK_OPTS="--exclude=SC1090,SC2086"

# gcloud
[[ -f ${HOME}/google-cloud-sdk/path.zsh.inc ]] && source ${HOME}/google-cloud-sdk/path.zsh.inc
[[ -f ${HOME}/google-cloud-sdk/completion.zsh.inc ]] && source ${HOME}/google-cloud-sdk/completion.zsh.inc

# Load local script
[[ -f ${HOME}/.local.zshenv ]] && source ${HOME}/.local.zshenv
