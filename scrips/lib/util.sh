#!/bin/bash

check_env() {
  for var_name in "$@"; do
    if [ -z "${!var_name}" ]; then
      echo "Error: Environment variable $var_name is not set."
      exit 1
    else
      echo "Environment variable $var_name is set to ${!var_name}"
    fi
  done
}
