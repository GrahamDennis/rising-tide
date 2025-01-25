# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{ config, pkgs, ... }:
let
  inherit (lib) types;
  cfg = config.languages.protobuf;
  protoc = ''
    protoc \
      --proto_path=$src \
      ${lib.concatMapStringsSep " " (path: "--proto_path=${path}") cfg.importPaths} \
      @<(find $src -name '*.proto') \
  '';
in
{
  options = {
    languages.protobuf = {
      enable = lib.mkEnableOption "Enable protobuf language configuration";
      grpc.enable = lib.mkEnableOption "Generate gRPC bindings";
      importPaths = lib.mkOption {
        description = ''
          Search paths for proto imports
        '';
        type = types.listOf types.path;
        default = [ ];
      };
      src = lib.mkOption {
        description = ''
          Protobuf sources
        '';
        type = types.path;
      };
      fileDescriptorSet = {
        callPackageFunction = lib.mkOption {
          description = ''
            The function to call to build the file descriptor set. This is expected to be called like:

            ```
            pkgs.callPackage callPackageFunction {}
            ```
          '';
          type = risingTideLib.types.callPackageFunction;
          default =
            { pkgs, stdenvNoCC, ... }:
            stdenvNoCC.mkDerivation {
              name = "${config.name}-fileDescriptorSet.pb";
              src = cfg.src;
              nativeBuildInputs = [ pkgs.protobuf ];

              installPhase = ''
                ${protoc} --descriptor_set_out=$out
              '';
            };
        };
        package = lib.mkOption {
          type = types.package;
          default = pkgs.callPackage cfg.fileDescriptorSet.callPackageFunction { };
        };
      };
      python = {
        generated = {
          callPackageFunction = lib.mkOption {
            description = ''
              The function to call to build the python protobuf bindings. This is expected to be called like:

              ```
              pkgs.callPackage callPackageFunction {}
              ```
            '';
            type = risingTideLib.types.callPackageFunction;
            default =
              { pkgs, stdenvNoCC, ... }:
              stdenvNoCC.mkDerivation {
                name = "${config.name}-protobuf-python-bindings";
                src = cfg.src;
                nativeBuildInputs = [
                  pkgs.protobuf
                  pkgs.mypy-protobuf
                ];

                installPhase = ''
                  mkdir -p $out
                  ${protoc} \
                    --python_out=$out --mypy_out=$out \
                    ${lib.optionalString cfg.grpc.enable "--plugin=protoc-gen-grpc_python=${pkgs.grpc}/bin/grpc_python_plugin --grpc_python_out=$out --mypy_grpc_out=$out"}
                '';
              };
          };
          package = lib.mkOption {
            type = types.package;
            default = pkgs.callPackage cfg.python.generated.callPackageFunction { };
          };
        };
      };
    };
  };
}
