#!/bin/bash

function @bashSafeName@PreShell() {
  echo "Executing @bashSafeName@ (pre-shell)"

  pushd "$FLAKE_ROOT" >/dev/null || return
  # Ensure the subproject exists
  mkdir -p "@relativePathToRoot@"
  cd "@relativePathToRoot@" || return
  @shellHooks@
  popd >/dev/null || return
}

preShellHooks+=(@bashSafeName@PreShell)
