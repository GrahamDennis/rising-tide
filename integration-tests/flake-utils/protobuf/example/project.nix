# project context
{
  ...
}:
{
  languages.protobuf = {
    enable = true;
    grpc.enable = true;
  };
  # tools.buf.experimental.breaking = {
  #   enable = true;
  #   # FIXME: This is awful to have to hardcode the path to the root of the project
  #   against = "$(git rev-parse --git-dir)#subdir=integration-tests/flake-utils/protobuf/${config.relativePaths.toRoot}/proto/";
  # };
}
