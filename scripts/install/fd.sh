#!/bin/bash

#####################################################################
# Pre
#####################################################################
script_dir=$(dirname "$(readlink -f "$0" || echo "$0")")
source "${script_dir}/../lib/util.sh"

tmp_dir="${XDG_CACHE_HOME:?}/tools/fd"
install_dir="${XDG_DATA_HOME:?}/tools/fd"
bin_dir="${XDG_BIN_HOME:?}"
mkdir -p "${tmp_dir}"
mkdir -p "${install_dir}"
mkdir -p "${bin_dir}"

rm -fr "${tmp_dir}"
mkdir -p "${tmp_dir}" && cd "${tmp_dir}" || exit 1

#####################################################################
# Main
#aarch64-unknown-linux-gnu.tar.gz
#####################################################################
version=$(curl -s https://api.github.com/repos/sharkdp/fd/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")')
if [[ "$OSTYPE" == "linux-gnu"* ]]; then
  bin="fd-${version}-x86_64-unknown-linux-gnu.tar.gz"
elif [[ "$OSTYPE" == "darwin"* ]]; then
  bin="fd-${version}-aarch64-apple-darwin.tar.gz"
else
  echo "Unsupported OS type: $OSTYPE"
  exit 1
fi

url="https://github.com/sharkdp/fd/releases/download/${version}/${bin}"

install_binary "${url}" "${bin}" "${install_dir}"

ln -sf "${install_dir}/fd" "${bin_dir}/fd"

#####################################################################
# Post
#####################################################################
rm -fr "${tmp_dir}"

echo "Complete fd install."

exit 0
