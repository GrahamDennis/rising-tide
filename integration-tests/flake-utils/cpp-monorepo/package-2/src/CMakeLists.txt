find_package(fmt)

add_executable(greet hello.cpp)
target_link_libraries(greet PRIVATE common_options fmt::fmt)

install(TARGETS greet)
