#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  mkdir -p build
  cp -r src build/
}

teardown() {
  rm -rf src
  mv build/src src
}

@test "can import and run python_package" {
  run python -c "import python_package; print(python_package.hello())"
  assert_success
  assert_output "Hello from python-package!"
}

@test "can import requests dependency" {
  run python -c "import requests"
  assert_success
}

@test "check task succeeds" {
  # Fail if the check task would modify files
  run env CI=1 task check
  assert_success
}

@test "can run ruff" {
  run task tool:ruff -- help
  assert_success
  assert_output --partial "Ruff: An extremely fast Python linter and code formatter."
}

@test "check task fails on poorly named functions" {
  # Fail if the check task would modify files
  sed -i -e 's/def bar/def bAr/' src/python_package/__init__.py
  run env CI=1 task check
  assert_failure
  assert_output --partial "N802"
}
