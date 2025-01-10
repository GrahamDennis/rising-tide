find_package(GTest)

include(GoogleTest)

add_executable(dummy_test dummy_test.cpp)
target_link_libraries(dummy_test PRIVATE common_options)

target_link_libraries(dummy_test PRIVATE
  GTest::gtest
  GTest::gtest_main
)

gtest_discover_tests(dummy_test)
