#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    bats_load_library bats-file
}

@test "taskfile.yml exists" {
    assert_link_exists taskfile.yml
}

@test "can execute hello task" {
    run task hello
    assert_success
    assert_output --partial "Hello, World!"
}

