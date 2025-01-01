#!/bin/bash

echo "Sourcing @bashSafeName@"

function @bashSafeName@() {
  echo "Executing @bashSafeName@"

  @nixagoHook@
}

findconfig() {
  # from: https://www.npmjs.com/package/find-config#algorithm
  # 1. If X/file.ext exists and is a regular file, return it. STOP
  # 2. If X has a parent directory, change X to parent. GO TO 1
  # 3. Return NULL.

  if [ -f "$1" ]; then
    printf '%s\n' "${PWD%/}/$1"
  elif [ "$PWD" = / ]; then
    false
  else
    # a subshell so that we don't affect the caller's $PWD
    (cd .. && findconfig "$1")
  fi
}

function @bashSafeName@PreShell() {
  echo "Executing @bashSafeName@ (pre-shell)"

  pushd "$(findconfig flake.nix)" >/dev/null || return
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
