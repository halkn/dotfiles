#!/bin/bash

#####################################################################
# main
#####################################################################
# before
script_dir=$(dirname "$(readlink -f "$0" || echo "$0")")
source "$script_dir/lib/util.sh"

declare -a XDG_DIRS=(
  "XDG_BIN_HOME"
  "XDG_CONFIG_HOME"
  "XDG_CACHE_HOME"
  "XDG_DATA_HOME"
)
check_env "${XDG_DIRS[@]}"

bin_dir=${XDG_BIN_HOME}
config_dir=${XDG_CONFIG_HOME}
cache_dir=${XDG_CACHE_HOME}
data_dir=${XDG_DATA_HOME}

# setup
mkdir -p "$bin_dir"
mkdir -p "$cache_dir/zsh"
mkdir -p "$data_dir/zsh"

if [[ -d "$config_dir" ]]; then
  unlink "$config_dir"
fi
echo "Link to xdg-configs: $config_dir"
ln -s "${HOME}/.dotfiles/.config" "$config_dir"

exit 0
