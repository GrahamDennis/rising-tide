enable_testing()

find_package(GTest)

add_executable(dummy_test1 dummy_test1.cpp)
target_link_libraries(dummy_test1 PRIVATE common_options)

target_link_libraries(dummy_test1 PRIVATE GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(dummy_test1)

# This causes tests to be run by running 'make test' and automatically as part of a nix build.
add_custom_target(test COMMAND ${CMAKE_CTEST_COMMAND})
add_dependencies(test dummy_test1)
