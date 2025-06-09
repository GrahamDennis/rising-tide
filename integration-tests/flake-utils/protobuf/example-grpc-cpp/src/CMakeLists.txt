
add_executable(hello-server hello-server.cpp)
target_link_libraries(
    hello-server
    PRIVATE common_options
    gRPC::grpc++ gRPC::grpc++_reflection
    example-cpp::default
    absl::check
    absl::flags
    absl::flags_parse
    absl::log
    absl::log_initialize
)

install(TARGETS hello-server)
