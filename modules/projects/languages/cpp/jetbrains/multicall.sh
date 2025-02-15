#!/bin/bash

if [ -n "$ZSH_VERSION" ]; then
  # zsh
  SCRIPT_DIR="${0:a:h}"
elif [ -n "$BASH_VERSION" ]; then
  SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
else
  echo "Unsupported shell"
  exit 1
fi

# shellcheck source=./env.sh
source "$SCRIPT_DIR/env.sh"

exec "$(basename "$0")" "$@"
