# # project injector context
# {
#   project,
#   ...
# }:
# packages context
{ pythonPackages }:
let
  inherit (pythonPackages) pkgs;
in
pkgs.runCommand "proto-bindings"
  {
    nativeBuildInputs = [
      pkgs.protobuf
      pkgs.grpc
      pythonPackages.mypy-protobuf
    ];
  }
  ''
    mkdir -p $out/{cpp,python}
    protoc \
      --proto_path=${./proto} \
      --descriptor_set_out=$out/file_descriptor_set.pb \
      --plugin=protoc-gen-grpc_cpp=${pkgs.grpc}/bin/grpc_cpp_plugin \
      --plugin=protoc-gen-grpc_python=${pkgs.grpc}/bin/grpc_python_plugin \
      --cpp_out=$out/cpp --grpc_cpp_out=$out/cpp \
      --python_out=$out/python --mypy_out=$out/python --grpc_python_out=$out/python --mypy_grpc_out=$out/python \
      @<(find ${./proto} -name '*.proto')
  ''
# pythonPackages.buildPythonPackage rec {
#   name = project.name;
#   pyproject = true;
#   src = ./.;

#   dependencies = with pythonPackages; [ requests ];

#   # FIXME: These should end up in the dev shell automatically
#   optional-dependencies = {
#     dev = with pythonPackages; [
#       pytest
#       pytest-cov
#     ];
#   };

#   nativeCheckInputs = project.allTools ++ optional-dependencies.dev;

#   build-system = with pythonPackages; [ hatchling ];
# }
