#!/bin/bash

if [ -n "$ZSH_VERSION" ]; then
  # zsh
  SCRIPT_DIR="${0:a:h}"
  pushd "$SCRIPT_DIR" >/dev/null || exit
  eval "$(@direnvPath@ export zsh 2>/dev/null)"
  popd >/dev/null || exit
elif [ -n "$BASH_VERSION" ]; then
  SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
  pushd "$SCRIPT_DIR" >/dev/null || exit
  eval "$(@direnvPath@ export bash 2>/dev/null)"
  popd >/dev/null || exit
else
  echo "Unsupported shell"
  exit 1
fi
