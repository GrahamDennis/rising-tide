#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
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
