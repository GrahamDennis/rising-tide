
add_executable(hello-server hello.cpp)
target_link_libraries(hello-server PRIVATE common_options gRPC::grpc++ example-cpp::default)

install(TARGETS hello-server)
