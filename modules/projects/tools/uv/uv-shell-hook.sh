#!/bin/bash

uvShellHook() {
  echo "Executing uvShellHook"

  # Encourage uv to find the version of python supplied by nix
  export UV_NO_MANAGED_PYTHON=1
  if [ ! -d .venv ]; then
    uv venv
  fi

  export VIRTUAL_ENV_DISABLE_PROMPT=1
  source .venv/bin/activate

  # Check if we need to update _nix_env.py
  if [ -f ".venv/python-path" ] && [ "${PYTHONPATH}" == "$(cat .venv/python-path)" ]; then
    true
  else
    echo "Updating _nix_env.py"
    # Configure the virtual environment to automatically pick up the Nix PYTHONPATH even if it is not activated
    # inside a nix develop shell (for VSCode & PyCharm)
    _SITE_PACKAGES_DIR=$(python -c "import site; print(site.getsitepackages()[0])")
    echo "import _nix_env" >"$_SITE_PACKAGES_DIR/_nix_env.pth"
    echo "import site" >"$_SITE_PACKAGES_DIR/_nix_env.py"
    for PYTHON_PATH_COMPONENT in $(echo "$PYTHONPATH" | tr ':' $'\n'); do
      echo "site.addsitedir(\"$PYTHON_PATH_COMPONENT\")" >>"$_SITE_PACKAGES_DIR/_nix_env.py"
    done
    echo "${PYTHONPATH}" >.venv/python-path
  fi

  local -a venvPackages
  runHook venvPackages

  # Check if we need to re-run uv pip install
  if [ -f ".venv/venv-packages" ] && [ "${venvPackages[*]}" == "$(cat .venv/venv-packages)" ]; then
    true
  else
    uv pip install --no-deps --offline --no-cache --no-build-isolation "${venvPackages[@]}"
    echo "${venvPackages[@]}" >.venv/venv-packages
  fi

  echo "Finished executing uvShellHook"
}

@name@VenvPackagesHook() {
  if test -f "${FLAKE_ROOT}/@relativePathFromRoot@/pyproject.toml"; then
    venvPackages+=(--editable "${FLAKE_ROOT}/@relativePathFromRoot@")
    addToSearchPath PYTHONPATH "${FLAKE_ROOT}/@relativePathFromRoot@/src"
  fi
}

if [ -z "${venvPackagesHooks:-}" ]; then
  preShellHooks+=(uvShellHook)
fi

venvPackagesHooks+=(@name@VenvPackagesHook)
