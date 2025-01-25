# project context
{
  ...
}:
{
  relativePaths.toParentProject = "proto-apis";
  languages.protobuf.enable = true;
  tools.buf.breaking = {
    # FIXME: This is awful to have to hardcode the path to the root of the project
    against = "../../../../.git#tag=$(git describe --tags --abbrev=0),subdir=integration-tests/flake-utils/protobuf/proto-apis/proto/";
  };
}
