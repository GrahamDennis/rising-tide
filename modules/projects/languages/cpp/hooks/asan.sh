# shellcheck shell=bash
export NIX_CFLAGS_COMPILE+=" @asanCflags@"
export ASAN_OPTIONS="@asanOptions@"
export LSAN_OPTIONS="@lsanOptions@"
