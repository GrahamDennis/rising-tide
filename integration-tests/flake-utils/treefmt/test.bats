#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
}

@test "taskfile.yml exists" {
  assert_link_exists taskfile.yml
}

@test "can execute check task" {
  run task check
  assert_success
}

@test "can execute check:treefmt task" {
  run task check:treefmt
  assert_success
}

@test "can execute tool:treefmt task" {
  run task tool:treefmt -- --help
  assert_success
  assert_output --partial "The formatter multiplexer"
}
