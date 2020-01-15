#!/bin/bash

# brew install
declare -a BREW_APPS=(
  "bat"
  "diff-so-fancy"
  "exa"
  "fd"
  "fzf"
  "ghq"
  "git"
  "go"
  "jq"
  "nodebrew"
  "p7zip"
  "ripgrep"
  "tig"
  "tmux"
  "vim"
  "zsh"
)

for brew_app in ${BREW_APPS[@]}; do
  brew_install_result=0
  $(brew leaves | grep -x ${brew_app} 2>&1 > /dev/null) || brew_install_result=$?
  if [[ ! "$brew_install_result" = "0"  ]]; then
    brew install ${brew_app}
  fi
done

echo 'Complete for Homebrew app installation'

# except XDG_CONFIG_HOME because it is maked by dotdiles deploy
if [[ -z ${XDG_CACHE_HOME}  ]]; then
  echo "XDG_CACHE_HOME is not defined"
  XDG_CACHE_HOME=$(cat .config/zsh/.zshenv | grep "export XDG_CACHE_HOME" | awk -F'=' '{print $2}')
  echo "mkdir for" $(eval echo ${XDG_CACHE_HOME}) 
  mkdir -p $(eval echo ${XDG_CACHE_HOME})
fi

if [[ -z ${XDG_DATA_HOME} ]]; then
  echo "XDG_DATA_HOME is not defined"
  XDG_DATA_HOME=$(cat .config/zsh/.zshenv | grep "export XDG_DATA_HOME" | awk -F'=' '{print $2}')
  echo "mkdir for" $(eval echo ${XDG_DATA_HOME}) 
  mkdir -p $(eval echo ${XDG_DATA_HOME})
fi

declare -a XDG_DIR=(
  "gem"
  "go"
  "nodebrew"
  "npm"
  "tig"
  "zsh"
)

for dir in ${XDG_DIR[@]}; do
  mkdir -p $(eval echo ${XDG_DATA_HOME})/${dir}
done

echo 'Complete for mkdir xdg directory'

# vim plugin manager
if [[ ! -e "$HOME/.vim/pack/minpac/opt/minpac" ]]; then
git clone https://github.com/k-takata/minpac.git \
    ~/.vim/pack/minpac/opt/minpac
fi

# go tools
export GO111MODULE=off
go get github.com/mattn/efm-langserver
export GO111MODULE=on

# npm tools
npm install -g bash-language-server
npm install -g vim-language-server
npm install -g markdownlint-cli

exit 0
