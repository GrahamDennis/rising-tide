#!/bin/bash

dotenvHook() {
  local DOTENV_TEMP_FILE
  DOTENV_TEMP_FILE="$(mktemp)"

  for variable in $(jq --raw-output '.variables|to_entries|map(select(.value.type == "exported" and (.value.value|contains("\n")|not)))|from_entries|keys[]' <"$NIX_GCROOT"); do
    echo "${variable}='${!variable}'" >>"$DOTENV_TEMP_FILE"
  done
  # To override PATH the env precedence go-task experiment must be enabled.
  # See https://taskfile.dev/experiments/env-precedence
  echo "TASK_X_ENV_PRECEDENCE=1" >>"$DOTENV_TEMP_FILE"
  mv "$DOTENV_TEMP_FILE" .env
}

postShellHooks+=(dotenvHook)
