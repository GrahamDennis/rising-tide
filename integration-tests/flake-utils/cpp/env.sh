#!/bin/bash

# SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SCRIPT_DIR=${0:a:h}

pushd "$SCRIPT_DIR" >/dev/null || exit
eval "$("/opt/homebrew/bin/direnv" export zsh)"
popd >/dev/null || exit
