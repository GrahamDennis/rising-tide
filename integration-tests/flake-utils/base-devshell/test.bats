#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file
}

@test "cowsay and COWSAY_CONTENT are available in shell" {
  run cowsay $COWSAY_CONTENT
  assert_success
  assert_output --partial "Hello, world!"
}
