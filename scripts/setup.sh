#!/bin/bash

print_start() {
  echo "# #####################################################################"
  echo "# Start :$1"
  echo "#"
}

print_end() {
  echo "#"
  echo "# End :$1"
  echo "# #####################################################################"
  echo ""
}

install_zsh_plugin() {
  owner=$1
  repo=$2

  source_url="https://github.com/$owner/$repo"
  dist_dir="${ZPLUGINDIR:?}/$repo"

  rm -fr "${dist_dir:?}"
  git clone "${source_url}" "${dist_dir}"
}

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

mes="Installing zsh plugins..."
print_start "$mes"
install_zsh_plugin "zsh-users" "zsh-autosuggestions"
install_zsh_plugin "zsh-users" "zsh-syntax-highlighting"
print_end "$mes"

exit 0
