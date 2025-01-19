#!/bin/bash

main() {
  owner=$1
  repo=$2

  source_url="https://github.com/$owner/$repo"
  dist_dir="${ZPLUGINDIR:?}/$repo"

  rm -fr "${dist_dir:?}"
  git clone "${source_url}" "${dist_dir}"
}

main "$@"

exit 0
