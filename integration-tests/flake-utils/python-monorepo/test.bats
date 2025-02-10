#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
}

nixBuild() {
  nix build --override-input rising-tide "$(git rev-parse --show-toplevel)" "$@"
}

@test "can import and run package_1" {
  run python -c "import package_1; print(package_1.hello())"
  assert_success
  assert_output "Hello from package-1!"
}

@test "can import and run package_2" {
  run python -c "import package_2; print(package_2.hello())"
  assert_success
  assert_output "Hello from package-2!"
}

@test "check task succeeds" {
  run task check
  assert_success
}

@test "test task succeeds" {
  run task test
  assert_success
}

@test "can run script published from package-1" {
  run package-1-hello
  assert_success
  assert_output "Hello from package-1!"
}

@test "can run script published from package-2" {
  run package-2-hello
  assert_success
  assert_output "Hello from package-2!"
}

@test "nix build of _all-project-packages" {
  run nixBuild .#_all-project-packages
  assert_success
}
