enable_testing()

find_package(GTest)

add_executable(dummy_test dummy_test.cpp)
target_link_libraries(dummy_test PRIVATE common_options)

target_link_libraries(dummy_test PRIVATE GTest::gtest_main)

include(GoogleTest)
gtest_discover_tests(dummy_test)

# This causes tests to be run by running 'make test' and automatically as part of a nix build.
add_custom_target(test COMMAND ${CMAKE_CTEST_COMMAND})
add_dependencies(test dummy_test)
