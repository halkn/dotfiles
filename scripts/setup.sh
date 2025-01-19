#!/bin/bash

# before
script_dir=$(dirname "$(readlink -f "$0" || echo "$0")")
source "$script_dir/lib/util.sh"

# variables
bin_dir=${XDG_BIN_HOME:?}
config_dir=${XDG_CONFIG_HOME:?}
cache_dir=${XDG_CACHE_HOME:?}
data_dir=${XDG_DATA_HOME:?}

# link
mes="Link to xdg-configs: $config_dir."
print_start "$mes"
if [[ -d "$config_dir" ]]; then
  unlink "$config_dir"
fi
ln -vs "${HOME}/.dotfiles/.config" "$config_dir"
print_end "$mes"

# for zsh
mes="setup directory for zsh."
print_start "$mes"
mkdir -vp "$bin_dir"
mkdir -vp "$cache_dir/zsh"
mkdir -vp "$data_dir/zsh"
print_end "$mes"

exit 0
