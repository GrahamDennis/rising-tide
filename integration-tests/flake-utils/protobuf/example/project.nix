# project context
{
  ...
}:
{
  languages.protobuf = {
    enable = true;
    grpc.enable = true;
  };
  tools.buf.experimental.breaking = {
    enable = true;
    # FIXME: This is awful to have to hardcode the path to the root of the project
    against = "../../../../.git#tag=$(git describe --tags --abbrev=0),subdir=integration-tests/flake-utils/protobuf/example/proto/";
  };
}
