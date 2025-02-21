#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
}

restore_in_teardown() {
  mkdir -p build/bats
  cp -R {src,tests}/ build/bats
}

teardown() {
  if [ -d build/bats/src ]; then
    cp -R build/bats/{src,tests} .
  fi
}

@test "nix build of package-1" {
  run nix build .#package-1
  assert_success
}

@test "nix build of package-2" {
  run nix build .#package-2
  assert_success
}

@test "nix build of _all-project-packages" {
  run nix build .#_all-project-packages
  assert_success
}
