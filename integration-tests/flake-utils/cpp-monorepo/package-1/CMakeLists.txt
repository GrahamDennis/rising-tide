cmake_minimum_required(VERSION 3.14)
project(FmtDemo LANGUAGES CXX)

add_library(common_options INTERFACE)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

target_compile_features(common_options INTERFACE cxx_std_20)
target_compile_options(common_options INTERFACE -Wall -Wextra)
target_include_directories(common_options INTERFACE src)

add_subdirectory(src)
add_subdirectory(tests)
