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

install_binary() {
  url=$1
  bin=$2
  install_dir=$3

  print_start "${bin} install"
  curl -LO "$url"

  mkdir -p ./tmp
  rm -fr "${install_dir:?}/"
  tar -xzf "${bin}" --strip-components 1 -C ./tmp
  cp -pr ./tmp "$install_dir"
  print_end "${bin} install"
}
