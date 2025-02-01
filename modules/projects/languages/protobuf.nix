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
      ${lib.concatMapAttrsStringSep " " (_name: path: "--proto_path=${path}") cfg.importPaths} \
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
        type = types.attrsOf types.path;
        default = { };
      };
      src = lib.mkOption {
        description = ''
          Protobuf sources
        '';
        type = types.path;
      };
      cpp = {
        generatedSources = {
          callPackageFunction = lib.mkOption {
            description = ''
              A `callPackage` function for the generated sources for the C++ protobuf bindings. This is expected to be called like:

              ```
              pkgs.callPackage callPackageFunction {}
              ```
            '';
            type = risingTideLib.types.callPackageFunction;
            default =
              { pkgs, stdenvNoCC, ... }:
              stdenvNoCC.mkDerivation {
                name = "${config.name}-protobuf-cpp-generated-src";
                src = cfg.src;
                nativeBuildInputs = [
                  pkgs.protobuf
                ];

                installPhase = ''
                  mkdir -p $out/src
                  ${protoc} \
                    --cpp_out=$out/src \
                    ${lib.optionalString cfg.grpc.enable "--plugin=protoc-gen-grpc_cpp=${pkgs.grpc}/bin/grpc_cpp_plugin --grpc_cpp_out=$out/src"}
                '';
              };
          };
          package = lib.mkOption {
            type = types.package;
            default = pkgs.callPackage cfg.cpp.generatedSources.callPackageFunction { };
            defaultText = lib.literalMD "A package containing generated sources for the C++ protobuf bindings.";
          };
        };
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
              let
                protoFiles = lib.fileset.toList (lib.fileset.fileFilter (file: file.hasExt "proto") cfg.src);
                pythonModules = builtins.map (lib.flip lib.pipe [
                  # Strip the absolute path prefix containing the protobuf files,
                  # e.g. /nix/store/eeeeee-source/my-subproject/proto/foo/bar.proto => "./foo/bar.proto"
                  (lib.path.removePrefix cfg.src)
                  # Strip the relative path prefix "./" to get a path like "foo/bar.proto"
                  (lib.removePrefix "./")
                  # Turn the file path into a python module name, e.g. "foo/bar.proto" -> "foo.bar_pb2"
                  (builtins.replaceStrings [ ".proto" "/" ] [ "_pb2" "." ])
                ]) protoFiles;
              in
              { pythonPackages }:
              pythonPackages.buildPythonPackage {
                name = cfg.python.packageName;
                pyproject = true;
                src = cfg.python.generatedSources.package;

                # Validate that all generated protobuf files are importable
                pythonImportsCheck = pythonModules;

                # FIXME: This may need additional dependencies for protobuf package dependencies
                dependencies =
                  (with pythonPackages; [
                    protobuf
                    types-protobuf
                  ])
                  ++ (lib.optionals cfg.grpc.enable (with pythonPackages; [ grpcio ]))
                  ++ (cfg.python.extraDependencies pythonPackages);

                build-system = [ pythonPackages.hatchling ];
              };
          };
          extraDependencies = lib.mkOption {
            description = ''
              A function from `pythonPackages` to a list of additional dependencies
              for the generated python package.
            '';
            type = types.functionTo (types.listOf types.package);
            default = _pythonPackages: [ ];
          };
          generatedSources = {
            callPackageFunction = lib.mkOption {
              description = ''
                A `callPackage` function for the generated sources for the Python protobuf bindings. This is expected to be called like:

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
                    toolsPkgs.mypy-protobuf
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
              default = pkgs.callPackage cfg.python.generatedSources.callPackageFunction { };
              defaultText = lib.literalMD "A package containing generated sources for the Python protobuf bindings.";
            };
          };
        };
    };
  };
  config = lib.mkIf cfg.enable {
    mkShell.nativeBuildInputs = [ config.languages.python.package ];
    languages.python = {
      enable = true;
      callPackageFunction = cfg.python.callPackageFunction;
    };
    languages.protobuf = {
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
          include = [ "src" ];
          sources = [ "src" ];
        };
        build-system = {
          requires = [ "hatchling" ];
          build-backend = "hatchling.build";
        };
      };
    };
  };
}
