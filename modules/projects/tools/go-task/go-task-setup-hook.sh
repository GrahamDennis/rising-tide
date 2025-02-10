#!/bin/bash

echo "Sourcing go-task-setup-hook"

function goTaskPostShellHook() {
  echo "Executing goTaskPostShellHook"

  eval "$(task --completion bash)"
}

postShellHooks+=(goTaskPostShellHook)
