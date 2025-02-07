#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
}

@test "check task succeeds" {
  run task check
  assert_success
}

@test "nix build of packages.system.cpp-package" {
  run nix build .#cpp-package
  assert_success
}

@test "nix build of legacyPackages.system.rising-tide.integration-tests.cpp.cpp-package" {
  run nix build .#rising-tide.integration-tests.cpp.cpp-package
  assert_success
}

@test "nix build with sanitizers packages.system.cpp-package" {
  run nix build .#cpp-package-with-asan .#cpp-package-with-tsan
  assert_success
}
