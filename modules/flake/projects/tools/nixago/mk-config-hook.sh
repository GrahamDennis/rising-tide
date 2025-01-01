#!/bin/bash

echo "Sourcing @bashSafeName@"

function @bashSafeName@() {
  echo "Executing @bashSafeName@"

  @nixagoHook@
}

function @bashSafeName@PreShell() {
  echo "Executing @bashSafeName@ (pre-shell)"

  pushd "$(@findup@ flake.nix)" >/dev/null || return
  cd "@relativePathToRoot@" || return
  @nixagoHook@
  popd >/dev/null || return
}

function uniqueArray() {
  declare -n array="$1"
  local -A associativeArray
  local i
  for i in "${array[@]}"; do associativeArray["$i"]=1; done
  array=("${!associativeArray[@]}")
}

function configShellHook() {
  echo "Executing configShellHook"
  uniqueArray preShellHooks
  runHook preShellHook

  # shellcheck disable=SC1091
  . "@bashCompletionPackage@/etc/profile.d/bash_completion.sh"

  uniqueArray postShellHooks
  runHook postShellHook
  echo "Finished executing configShellHook"
}

postPatchHooks+=(@bashSafeName@)
preShellHooks+=(@bashSafeName@PreShell)
# shellcheck disable=SC2034
shellHook=configShellHook
