#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
}

# FIXME: Can this be loaded as a bats library?
nixBuild() {
  nix build --override-input rising-tide "$(git rev-parse --show-toplevel)" "$@"
}

@test "check task succeeds" {
  run task check
  assert_success
}

@test "nix build of packages.system.cpp-package" {
  run nixBuild .#cpp-package
  assert_success
}

@test "nix build of legacyPackages.system.rising-tide.integration-tests.cpp.cpp-package" {
  run nixBuild .#rising-tide.integration-tests.cpp.cpp-package
  assert_success
}

@test "nix build with sanitizers" {
  run nixBuild .#cpp-package-with-asan .#cpp-package-with-tsan
  assert_success
}

@test "nix build of _all-project-packages" {
  run nixBuild .#_all-project-packages
  assert_success
}
