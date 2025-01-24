#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  mkdir -p build
  cp -r proto-apis/ build/
}

teardown() {
  rm -rf proto-apis/
  mv build/proto-apis .
}

@test "check task succeeds" {
  run task check
  assert_success
}

@test "check task fails if a package definition is wrong" {
  sed -i -e 's/package example.v1;/package example.v2;/' proto-apis/proto/example/v1/hello.proto
  run task check
  assert_failure
  assert_output --partial 'must be within a directory "example/v2"'
}

@test "check task fails on poorly named messages" {
  sed -i -e 's/SearchRequest/search_request/' proto-apis/proto/example/v1/hello.proto
  run task check
  assert_failure
  assert_output --partial "should be PascalCase"
}
