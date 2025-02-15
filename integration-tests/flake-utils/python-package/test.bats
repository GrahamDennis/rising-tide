#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  rm -rf build/bats
}

restore_src_in_teardown() {
  mkdir -p build/bats
  cp -R {src,tests} build/bats
}

teardown() {
  if [ -d build/bats/src ]; then
    cp -R build/bats/{src,tests} .
  fi
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
  run task check
  assert_success
}

@test "can run ruff" {
  run task tool:ruff -- help
  assert_success
  assert_output --partial "Ruff: An extremely fast Python linter and code formatter."
}

@test "check task fails on poorly named functions" {
  restore_src_in_teardown
  sed -i -e 's/def bar/def bAr/' src/python_package/__init__.py
  run task check
  assert_failure
  assert_output --partial "N802"
}

@test "check fails on incorrect type hints" {
  restore_src_in_teardown
  sed -i -e 's/def hello() -> str:/def hello() -> int:/' src/python_package/__init__.py
  run task check:mypy
  assert_failure
  assert_output --partial "[return-value]"

  run task check:pyright
  assert_failure
  assert_output --partial "(reportReturnType)"
}

@test "check fails on missing type hints" {
  restore_src_in_teardown
  sed -i -e 's/def hello() -> str:/def hello():/' src/python_package/__init__.py
  run task check:mypy
  assert_failure
  assert_output --partial "[no-untyped-def]"
}

@test "test task succeeds" {
  run task test
  assert_success
}

@test "test check succeeds" {
  run task check
  assert_success
}

@test "test fails on test failure" {
  restore_src_in_teardown
  sed -i -e 's/Hello from/Goodbye from/g' tests/test_trivial.py
  run task test
  assert_failure
  assert_output --partial "assert 'Hello from python-package!' == 'Goodbye from python-package!'"

  run nix build --show-trace --log-lines 500 .#python-package
  assert_failure
  assert_output --partial "assert 'Hello from python-package!' == 'Goodbye"
}

@test "can run script published from package" {
  run hello
  assert_success
  assert_output "Hello from python-package!"
}

@test "nix build of _all-project-packages" {
  run nix build .#_all-project-packages
  assert_success
}

# @test "ci:check-not-dirty task fails for dirty repos" {
#   restore_src_in_teardown
#   sed -i -e 's/def hello() -> str:/def hello():/' src/python_package/__init__.py
#   run task ci:check-not-dirty
#   assert_failure
#   assert_output --partial 'Failed to run task "ci:check-not-dirty": exit status 1'
# }
