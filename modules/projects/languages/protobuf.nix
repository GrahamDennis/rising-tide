# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{
  config,
  pkgs,
  toolsPkgs,
  ...
}:
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
          defaultText = lib.literalMD "A package containing a single file which is the serialised file descriptor set";
        };
      };
      python =
        let
          settingsFormat = toolsPkgs.formats.toml { };
          pyprojectConfigFile = settingsFormat.generate "pyproject.toml" cfg.python.pyproject;
        in
        {
          packageName = lib.mkOption {
            description = ''
              The name of the python package to generate
            '';
            type = types.str;
            default = config.name;
            defaultText = lib.literalExpression "config.name";
          };
          pyproject = lib.mkOption {
            description = ''
              The pyproject.toml file to generate
            '';
            type = settingsFormat.type;
            default = { };
          };
          callPackageFunction = lib.mkOption {
            description = ''
              The function to call to build the python library. This is expected to be called like:

              ```
              pythonPackages.callPackage callPackageFunction {}
              ```
            '';
            type = risingTideLib.types.callPackageFunction;
            default =
              { pythonPackages }:
              pythonPackages.buildPythonPackage {
                name = cfg.python.packageName;
                pyproject = true;
                src = cfg.python.generated.package;

                dependencies =
                  (with pythonPackages; [
                    protobuf
                    types-protobuf
                  ])
                  ++ (lib.optionals cfg.grpc.enable (with pythonPackages; [ grpcio ]));

                build-system = [ pythonPackages.hatchling ];
              };
          };
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
                  name = "${config.name}-protobuf-python-generated-src";
                  src = cfg.src;
                  nativeBuildInputs = [
                    pkgs.protobuf
                    pkgs.mypy-protobuf
                  ];

                  installPhase = ''
                    mkdir -p $out/src
                    ${protoc} \
                      --python_out=$out/src --mypy_out=$out/src \
                      ${lib.optionalString cfg.grpc.enable "--plugin=protoc-gen-grpc_python=${pkgs.grpc}/bin/grpc_python_plugin --grpc_python_out=$out/src --mypy_grpc_out=$out/src"}
                    find $out -name '*.py' -execdir touch __init__.py py.typed \;
                    cp ${pyprojectConfigFile} $out/pyproject.toml
                  '';
                };
            };
            package = lib.mkOption {
              type = types.package;
              default = pkgs.callPackage cfg.python.generated.callPackageFunction { };
              defaultText = lib.literalMD "A package containing the protoc-generated python protobuf bindings";
            };
          };
        };
    };
  };
  config.languages.protobuf = {
    python.pyproject = {
      project = {
        name = cfg.python.packageName;
        version = "0.1.0";
        description = "Generated protobuf bindings for ${cfg.python.packageName}";
        dependencies = [
          "protobuf"
          "types-protobuf"
        ] ++ (lib.optionals cfg.grpc.enable [ "grpcio" ]);
      };
      tool.hatch.build.targets.wheel = {
        include = [ "src" ];
        sources = [ "src" ];
      };
      tool.hatch.build.targets.sdist = {
        sources = [ "src" ];
      };
      build-system = {
        requires = [ "hatchling" ];
        build-backend = "hatchling.build";
      };
    };
  };
}
