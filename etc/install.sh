#!/bin/bash

# Check install condition
if [[ -z ${XDG_CACHE_HOME}  ]]; then
  echo "XDG_CACHE_HOME is not defined"
  exit 1
fi

if [[ -z ${XDG_DATA_HOME} ]]; then
  echo "XDG_DATA_HOME is not defined"
  exit 1
fi

# if [[ ! -x /usr/local/bin/brew ]]; then
if !(type brew > /dev/null 2>&1); then
  echo "homebrew is not installed"
  exit 1
fi

echo 'Start for Homebrew app installation'
declare -a BREW_APPS=(
  "bash"
  "bash-completion"
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
  "tmux"
  "vim"
  "zsh"
)

for brew_app in ${BREW_APPS[@]}; do
  brew_install_result=0
  $(brew leaves | grep -x ${brew_app} 2>&1 > /dev/null) || brew_install_result=$?
  if [[ ! "$brew_install_result" = "0"  ]]; then
    brew install ${brew_app}
  else
    echo '  '${brew_app}' skipped'
  fi
done
echo 'Complete for Homebrew app installation'

echo ''

echo 'Start for mkdir xdg directory'
declare -a XDG_DIR=(
  ${XDG_DATA_HOME}"/bash"
  ${XDG_DATA_HOME}"/gem"
  ${XDG_DATA_HOME}"/go"
  ${XDG_DATA_HOME}"/nodebrew"
  ${XDG_DATA_HOME}"/npm"
  ${XDG_DATA_HOME}"/zsh"
  ${XDG_CACHE_HOME}"/vim/.undodir"
)

for dir in ${XDG_DIR[@]}; do
  echo '  mkdir for '${dir}
  mkdir -p ${dir}
done

echo 'Complete for mkdir xdg directory'

echo ''

# prompt
if [ ! -f "$XDG_DATA_HOME/gitstatus/gitstatus.prompt.sh" ]; then
  git clone --depth=1 https://github.com/romkatv/gitstatus $XDG_DATA_HOME/gitstatus
fi

# vim plugin manager
if [[ ! -e "$HOME/.vim/pack/minpac/opt/minpac" ]]; then
  git clone https://github.com/k-takata/minpac.git \
    ~/.vim/pack/minpac/opt/minpac
fi

exit 0
