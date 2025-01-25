#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  mkdir -p build
  cp -r example/ build/
}

teardown() {
  rm -rf example/
  mv build/example .
}

@test "check task succeeds" {
  run task check
  assert_success
}

@test "check task fails if a package definition is wrong" {
  sed -i -e 's/package example.v1;/package example.v2;/' example/proto/example/v1/hello.proto
  run task example:check:treefmt
  assert_failure
  assert_output --partial 'must be within a directory "example/v2"'
}

@test "check task fails on poorly named messages" {
  sed -i -e 's/SearchRequest/search_request/' example/proto/example/v1/hello.proto
  run task example:check:treefmt
  assert_failure
  assert_output --partial "should be PascalCase"
}

@test "check task fails on breaking change" {
  sed -i -e 's/string query = 1;//' example/proto/example/v1/hello.proto
  run task example:check:buf-breaking
  assert_failure
  assert_output --partial 'Previously present field "1" with name "query"'
}

@test "can import python protobuf bindings" {
  run python -c "import example.v1.hello_pb2"
  assert_success
}
