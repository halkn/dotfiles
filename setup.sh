#!/bin/bash

# Check install condition
if [[ -z ${XDG_CACHE_HOME} ]]; then
  echo "XDG_CACHE_HOME is not defined"
  exit 1
fi

if [[ -z ${XDG_DATA_HOME} ]]; then
  echo "XDG_DATA_HOME is not defined"
  exit 1
fi

# mkdir xdf directory
echo 'Start for mkdir xdg directory'
declare -a XDG_DIR=(
  "${XDG_DATA_HOME}/zsh"
  "$XDG_CACHE_HOME/zsh"
)

for dir in "${XDG_DIR[@]}"; do
  echo '  mkdir for '${dir}
  mkdir -p ${dir}
done

# Install

# zsh plugin
if [[ ! -d "$XDG_DATA_HOME/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    $XDG_DATA_HOME/zsh-autosuggestions
fi
if [[ ! -d "$XDG_DATA_HOME/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    $XDG_DATA_HOME/zsh-syntax-highlighting
fi

# prompt
if ! type starship > /dev/null 2>&1; then
  curl -sS https://starship.rs/install.sh | sh
fi

exit 0

