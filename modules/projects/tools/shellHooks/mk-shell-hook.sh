#!/bin/bash

echo "Sourcing @bashSafeName@"

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
    pushd .. >/dev/null || return
    findconfig "$1"
    popd >/dev/null || return
  fi
}

function @bashSafeName@PreShell() {
  echo "Executing @bashSafeName@ (pre-shell)"

  pushd "$FLAKE_ROOT" >/dev/null || return
  # Ensure the subproject exists
  mkdir -p "@relativePathToRoot@"
  cd "@relativePathToRoot@" || return
  @shellHooks@
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

  if [ -z "${FLAKE_ROOT:-}" ]; then
    FLAKE_ROOT="$(dirname "$(findconfig flake.nix)")"
    export FLAKE_ROOT
  fi

  uniqueArray preShellHooks
  runHook preShellHook

  . "@bashCompletionPackage@/etc/profile.d/bash_completion.sh"

  uniqueArray postShellHooks
  runHook postShellHook
  echo "Finished executing configShellHook"

  # Redefine function to avoid re-execution
  # shellcheck disable=SC2317
  function configShellHook() { :; }
}

preShellHooks+=(@bashSafeName@PreShell)
