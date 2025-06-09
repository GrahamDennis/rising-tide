cmake_minimum_required(VERSION 3.14)
project(ExampleGrpcCpp LANGUAGES CXX)

add_library(common_options INTERFACE)
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

target_compile_features(common_options INTERFACE cxx_std_20)
target_compile_options(common_options INTERFACE -Wall -Wextra)
target_include_directories(common_options INTERFACE src)

find_package(absl REQUIRED)
find_package(gRPC REQUIRED)
find_package(example-cpp REQUIRED)

add_subdirectory(src)
# add_subdirectory(tests)
