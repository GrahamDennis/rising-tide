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

@test "nix build with sanitizers" {
  run nix build .#cpp-package-with-asan .#cpp-package-with-tsan
  assert_success
}

@test "nix build of _all-project-packages" {
  run nix build .#_all-project-packages
  assert_success
}

@test "ci task" {
  run task ci
  assert_success
}

@test "ASAN build catches invalid memory access" {
  restore_in_teardown
  cat <<EOF >>tests/dummy_test.cpp

TEST(ASanTest, Foo) {
  int* z = new int[1024];
  delete[] z;
  EXPECT_EQ(z[0], 1);
}

EOF

  run task nix-build:cpp-package-with-asan
  assert_failure
  assert_output --regexp 'ASanTest\.Foo \((Subprocess aborted|Failed)\)'
}

@test "TSAN build catches data races" {
  restore_in_teardown
  cat <<EOF >>tests/dummy_test.cpp

#include <pthread.h>
int Global;
void *Thread1(void *x) {
  Global = 42;
  return x;
}

TEST(TSanTest, Foo) {
  pthread_t t;
  pthread_create(&t, NULL, Thread1, NULL);
  Global = 43;
  pthread_join(t, NULL);
  EXPECT_NE(Global, 40);
}

EOF

  run task nix-build:cpp-package-with-tsan
  assert_failure
  assert_output --regexp 'TSanTest\.Foo \((Subprocess aborted|Failed)\)'
}
