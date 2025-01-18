#!/bin/bash

#####################################################################
# functions
#####################################################################
install_zplugin() {
  owner=$1
  repo=$2

  GITHUB_BASE="https://github.com"

  if [[ ! -d "${ZPLUGINDIR}/$repo" ]]; then
    git clone "${GITHUB_BASE}/$owner/$repo" \
      "${ZPLUGINDIR}/$repo"
  fi
}

#####################################################################
# main
#####################################################################
# before
script_dir=$(dirname "$(readlink -f "$0" || echo "$0")")
source "$script_dir/lib/util.sh"

declare -a ENV_VARS=(
  "ZPLUGINDIR"
)

# process
check_env "${ENV_VARS[@]}"

install_zplugin "zsh-users" "zsh-autosuggestions"
install_zplugin "zsh-users" "zsh-syntax-highlighting"

exit 0
