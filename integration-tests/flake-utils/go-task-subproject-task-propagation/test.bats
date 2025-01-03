#!/usr/bin/env bats

setup() {
    bats_load_library bats-support
    bats_load_library bats-assert
    bats_load_library bats-file
}

@test "taskfile.yml exists" {
    assert_link_exists taskfile.yml
}

@test "subproject taskfile.yml exists" {
    assert_link_exists subproject/taskfile.yml
}


@test "can execute hello task in subproject" {
    cd subproject;
    run task hello
    assert_success
    assert_output --partial "Hello, World!"
}

@test "can execute hello task in parent project" {
    run task hello
    assert_success
    assert_output --partial "Hello, World!"
}


@test "can execute subproject's hello task from parent project" {
    run task subproject:hello
    assert_success
    assert_output --partial "Hello, World!"
}

