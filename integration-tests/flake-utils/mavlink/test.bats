#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  rm -rf build/bats
}

restore_src_in_teardown() {
  mkdir -p build/bats
  cp -R example/ build/bats
}

teardown() {
  if [ -d build/bats/example ]; then
    cp -R build/bats/example .
  fi
}

@test "check task succeeds" {
  run task check
  assert_success
}

@test "nix build of _all-project-packages" {
  run nix build .#_all-project-packages
  assert_success
}

@test "can run task build" {
  run task build
  assert_success
}

@test "ci task passes" {
  run task ci
  assert_success
}

@test "check task fails on breaking change" {
  restore_src_in_teardown
  sed -i -e 's/name="idx"/name="idx2"/' example/mavlink/example.xml
  run task example:test:cue-schema-breaking
  assert_failure
  assert_output --partial 'does not subsume'
}
