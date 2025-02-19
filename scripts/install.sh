#!/bin/bash

# load funcions
script_dir=$(dirname "$(readlink -f "$0" || echo "$0")")
source "$script_dir/lib/util.sh"

mes="install zsh plugins."
print_start "$mes"
bash "${script_dir}/install/zsh-plugins.sh" "zsh-users" "zsh-autosuggestions"
bash "${script_dir}/install/zsh-plugins.sh" "zsh-users" "zsh-syntax-highlighting"
print_end "$mes"

exit 0
