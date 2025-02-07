# shellcheck shell=bash
export NIX_CFLAGS_COMPILE+=" @tsanCflags@"
export TSAN_OPTIONS="@tsanOptions@"
