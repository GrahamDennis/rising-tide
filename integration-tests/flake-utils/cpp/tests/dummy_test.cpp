#include <gtest/gtest.h>

TEST(misc, passing) { ASSERT_EQ(1, 1); }

TEST(HelloTest, BasicAssertions) {
  // Expect two strings not to be equal.
  EXPECT_STRNE("hello", "world");
  // Expect equality.
  EXPECT_EQ(7 * 6, 42);
}

TEST(FOO, ASAN) {
  int *array = new int[100];
  delete[] array;
  delete[] array;
  EXPECT_NO_THROW(array[3]);  // BOOM
}