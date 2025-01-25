#!/bin/bash

uvShellHook() {
  echo "Executing uvShellHook"

  uv venv --allow-existing
  export VIRTUAL_ENV_DISABLE_PROMPT=1
  # shellcheck disable=SC1091
  source .venv/bin/activate

  # Configure the virtual environment to automatically pick up the Nix PYTHONPATH even if it is not activated
  # inside a nix develop shell (for VSCode & PyCharm)
  _SITE_PACKAGES_DIR=$(python -c "import site; print(site.getsitepackages()[0])")
  echo "import _nix_env" >"$_SITE_PACKAGES_DIR/_nix_env.pth"
  echo "import site" >"$_SITE_PACKAGES_DIR/_nix_env.py"
  for PYTHON_PATH_COMPONENT in $(echo "$PYTHONPATH" | tr ':' $'\n'); do
    echo "site.addsitedir(\"$PYTHON_PATH_COMPONENT\")" >>"$_SITE_PACKAGES_DIR/_nix_env.py"
  done

  runHook postVenvCreation
  echo "Finished executing uvShellHook"
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

@name@PostVenvCreationHook() {
  echo "Executing @name@PostVenvCreationHook"
  local projectRoot
  projectRoot="$(dirname "$(findconfig flake.nix)")"
  if test -f "${projectRoot}/@relativePathToRoot@/pyproject.toml"; then
    uv pip install -e "${projectRoot}/@relativePathToRoot@" --no-deps --offline --no-cache --no-build-isolation
    addToSearchPath PYTHONPATH "${projectRoot}/@relativePathToRoot@/src"
  fi
}

if [ -z "${postVenvCreationHooks:-}" ]; then
  preShellHooks+=(uvShellHook)
fi

postVenvCreationHooks+=(@name@PostVenvCreationHook)
