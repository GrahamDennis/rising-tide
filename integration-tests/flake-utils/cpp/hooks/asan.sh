# shellcheck shell=bash
export NIX_CFLAGS_COMPILE+=" -fsanitize=address -O1 -fno-omit-frame-pointer -fno-optimize-sibling-calls"
