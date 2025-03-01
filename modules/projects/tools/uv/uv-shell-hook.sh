#!/bin/bash

uvShellHook() {
  echo "Executing uvShellHook"

  export VIRTUAL_ENV_DISABLE_PROMPT=1

  local -a venvPackages
  runHook venvPackages

  # Check if we need to recreate the virtual environment
  if [ "$(readlink .venv/nix-env)" == "${NIX_GCROOT}" ] && [ "${PYTHONPATH}" == "$(cat .venv/python-path)" ]; then
    source .venv/bin/activate
  else
    # Remove the old virtual environment if it exists
    rm -rf .venv
    echo "Recreating the python virtual environment"
    uv venv
    source .venv/bin/activate

    # Configure the virtual environment to automatically pick up the Nix PYTHONPATH even if it is not activated
    # inside a nix develop shell (for VSCode & PyCharm)
    _SITE_PACKAGES_DIR=$(python -c "import site; print(site.getsitepackages()[0])")
    echo "import _nix_env" >"$_SITE_PACKAGES_DIR/_nix_env.pth"
    echo "import site" >"$_SITE_PACKAGES_DIR/_nix_env.py"
    for PYTHON_PATH_COMPONENT in $(echo "$PYTHONPATH" | tr ':' $'\n'); do
      echo "site.addsitedir(\"$PYTHON_PATH_COMPONENT\")" >>"$_SITE_PACKAGES_DIR/_nix_env.py"
    done

    uv pip install --no-deps --offline --no-cache --no-build-isolation "${venvPackages[@]}"

    ln -fs "${NIX_GCROOT}" .venv/nix-env
    echo "${PYTHONPATH}" >.venv/python-path
  fi

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

if [ -z "${FLAKE_ROOT:-}" ]; then
  FLAKE_ROOT="$(dirname "$(findconfig flake.nix)")"
fi

@name@VenvPackagesHook() {
  echo "Executing @name@VenvPackagesHook"
  if test -f "${FLAKE_ROOT}/@relativePathToRoot@/pyproject.toml"; then
    venvPackages+=(--editable "${FLAKE_ROOT}/@relativePathToRoot@")
    addToSearchPath PYTHONPATH "${FLAKE_ROOT}/@relativePathToRoot@/src"
  fi
}

if [ -z "${venvPackagesHooks:-}" ]; then
  preShellHooks+=(uvShellHook)
fi

venvPackagesHooks+=(@name@VenvPackagesHook)
