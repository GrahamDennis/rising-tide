# shellcheck shell=bash
export NIX_CFLAGS_COMPILE+=" -fprofile-instr-generate -fcoverage-mapping"
