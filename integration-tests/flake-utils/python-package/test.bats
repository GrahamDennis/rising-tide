#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  mkdir -p build
  cp -r src tests build/
}

teardown() {
  rm -rf src tests
  mv build/{src,tests} .
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
  sed -i -e 's/def bar/def bAr/' src/python_package/__init__.py
  run task check
  assert_failure
  assert_output --partial "N802"
}

@test "check fails on incorrect type hints" {
  sed -i -e 's/def hello() -> str:/def hello() -> int:/' src/python_package/__init__.py
  run task check
  assert_failure
  assert_output --partial "[return-value]"
}

@test "check fails on missing type hints" {
  sed -i -e 's/def hello() -> str:/def hello():/' src/python_package/__init__.py
  run task check
  assert_failure
  assert_output --partial "[no-untyped-def]"
}

@test "test task succeeds" {
  run task test
  assert_success
}

@test "test fails on test failure" {
  sed -i -e 's/Hello from/Goodbye from/g' tests/test_trivial.py
  run task test
  assert_failure
  assert_output --partial "assert 'Hello from python-package!' == 'Goodbye from python-package!'"
}

@test "can run script published from package" {
  run hello
  assert_success
  assert_output "Hello from python-package!"
}
