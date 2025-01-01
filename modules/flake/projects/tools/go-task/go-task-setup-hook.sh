#!/bin/bash

echo "Sourcing go-task-check-hook"

function goTaskCheckHook() {
  echo "Executing goTaskCheckHook"

  # Run the 'check' and 'test' tasks
  eval "task check test"

  echo "Finished executing goTaskCheckHook"
}

function goTaskPostShellHook() {
  echo "Executing goTaskPostShellHook"

  eval "$(task --completion bash)"
}

if [ -z "${dontUseGoTaskCheck-}" ]; then
  echo "Using goTaskCheckHook"
  postInstallCheckHooks+=(goTaskCheckHook)
fi

postShellHooks+=(goTaskPostShellHook)
