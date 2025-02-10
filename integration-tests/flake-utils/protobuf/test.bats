#!/usr/bin/env bats

setup() {
  bats_load_library bats-support
  bats_load_library bats-assert
  bats_load_library bats-file

  rm -rf build/bats
}

restore_src_in_teardown() {
  mkdir -p build/bats
  cp -r example/ build/bats
}

teardown() {
  if [ -d build/bats/example ]; then
    rm -rf example/
    mv build/bats/example .
  fi
}

nixBuild() {
  nix build --override-input rising-tide "$(git rev-parse --show-toplevel)" "$@"
}

@test "check task succeeds" {
  run task check
  assert_success
}

@test "check task fails if a package definition is wrong" {
  restore_src_in_teardown
  sed -i -e 's/package example.v1;/package example.v2;/' example/proto/example/v1/hello.proto
  cat example/proto/example/v1/hello.proto
  run task example:check:treefmt
  assert_failure
  assert_output --partial 'must be within a directory "example/v2"'
}

@test "check task fails on poorly named messages" {
  restore_src_in_teardown
  sed -i -e 's/SearchRequest/search_request/' example/proto/example/v1/hello.proto
  run task example:check:treefmt
  assert_failure
  assert_output --partial "should be PascalCase"
}

@test "check task fails on breaking change" {
  restore_src_in_teardown
  sed -i -e 's/string query = 1;//' example/proto/example/v1/hello.proto
  run task example:check:buf-breaking
  assert_failure
  assert_output --partial 'Previously present field "1" with name "query"'
}

@test "can import python protobuf bindings" {
  run python -c "import example.v1.hello_pb2"
  assert_success
}

@test "can build all generated sources" {
  run nixBuild .#example-file-descriptor-set .#example-generated-sources-cpp .#example-generated-sources-py
  assert_success
}

@test "can build renamed package" {
  run nixBuild .#example-extended-py-with-custom-name
  assert_success
}

@test "generated file descriptor sets are self-contained" {
  run nixBuild .#example-curl
  assert_success
  run ./result list
  assert_success
  assert_output "example.v1.GreeterService"
}

@test "can build C++ projects" {
  run nixBuild .#example-cpp .#example-extended-cpp
  assert_success
}

@test "nix build of _all-project-packages" {
  run nixBuild .#_all-project-packages
  assert_success
}
