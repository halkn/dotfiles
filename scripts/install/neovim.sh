#!/bin/bash

#####################################################################
# Pre
#####################################################################
script_dir=$(dirname "$(readlink -f "$0" || echo "$0")")
source "${script_dir}/../lib/util.sh"

tmp_dir="${XDG_CACHE_HOME:?}/tools/neovim"
install_dir="${XDG_DATA_HOME:?}/tools/neovim"
bin_dir="${XDG_BIN_HOME:?}"
mkdir -p "${tmp_dir}"
mkdir -p "${install_dir}"
mkdir -p "${bin_dir}"

rm -fr "${tmp_dir}"
mkdir -p "${tmp_dir}" && cd "${tmp_dir}" || exit 1

#####################################################################
# Main
#####################################################################
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  bin="nvim-linux64.tar.gz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  bin="nvim-macos-arm64.tar.gz"
else
  echo "Unsupported OS type: $OSTYPE"
  exit 1
fi

url="https://github.com/neovim/neovim/releases/download/nightly/${bin}"

install_binary "${url}" "${bin}" "${install_dir}"

ln -sf "${install_dir}/bin/nvim" "${bin_dir}/nvim"

#####################################################################
# Post
#####################################################################
rm -fr "${tmp_dir}"

echo "Complete neovim install."

exit 0
