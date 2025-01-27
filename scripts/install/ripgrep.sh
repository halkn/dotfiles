#!/bin/bash

#####################################################################
# Pre
#####################################################################
# before
script_dir=$(dirname "$(readlink -f "$0" || echo "$0")")
source "${script_dir}/../lib/util.sh"

tmp_dir="${XDG_CACHE_HOME:?}/tools/ripgrep"
install_dir="${XDG_DATA_HOME:?}/tools/ripgrep"
bin_dir="${XDG_BIN_HOME:?}"
mkdir -p "${tmp_dir}"
mkdir -p "${install_dir}"
mkdir -p "${bin_dir}"

rm -fr "${tmp_dir}"
mkdir -p "${tmp_dir}" && cd "${tmp_dir}" || exit 1

#####################################################################
# Main
#####################################################################
version=$(curl -s https://api.github.com/repos/BurntSushi/ripgrep/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  bin="ripgrep-${version}-x86_64-unknown-linux-musl.tar.gz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  bin="ripgrep-${version}-aarch64-apple-darwin.tar.gz"
else
  echo "Unsupported OS type: $OSTYPE"
  exit 1
fi

url="https://github.com/BurntSushi/ripgrep/releases/download/${version}/${bin}"

install_binary "${url}" "${bin}" "${install_dir}"

ln -sf "${install_dir}/rg" "${bin_dir}/rg"

#####################################################################
# Post
#####################################################################
rm -fr "${tmp_dir}"

echo "Complete ripgrep install."

exit 0
