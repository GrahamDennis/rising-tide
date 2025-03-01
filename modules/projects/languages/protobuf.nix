# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
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
  subprojects = lib.mapAttrsRecursive (_path: value: config.subprojects.${value}) cfg.subprojectNames;

  protoFileset = lib.fileset.fileFilter (file: file.hasExt "proto") cfg.src;

  absoluteProtoPaths = lib.fileset.toList protoFileset;
  relativeProtoPaths = builtins.map (lib.flip lib.pipe [
    # Strip the absolute path prefix containing the protobuf files,
    # e.g. /nix/store/eeeeee-source/my-subproject/proto/foo/bar.proto => "./foo/bar.proto"
    (lib.path.removePrefix cfg.src)
    # Strip the relative path prefix "./" to get a path like "foo/bar.proto"
    (lib.removePrefix "./")
  ]) absoluteProtoPaths;

  protoSrc = lib.fileset.toSource {
    root = cfg.src;
    fileset = protoFileset;
  };

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
        extraDependencies = lib.mkOption {
          description = ''
            A function from `pkgs` to a list of additional dependencies
            for the generated C++ library.
          '';
          type = types.functionTo (types.listOf types.package);
          default = _pkgs: [ ];
        };
      };
      python = {
        extraDependencies = lib.mkOption {
          description = ''
            A function from `pythonPackages` to a list of additional dependencies
            for the generated python package.
          '';
          type = types.functionTo (types.listOf types.package);
          default = _pythonPackages: [ ];
        };
      };
      subprojectNames = {
        generatedSources.python = lib.mkOption {
          type = types.str;
          default = "${config.packageName}-generated-sources-py";
        };
        generatedSources.cpp = lib.mkOption {
          type = types.str;
          default = "${config.packageName}-generated-sources-cpp";
        };
        python = lib.mkOption {
          type = types.str;
          default = "${config.packageName}-py";
        };
        cpp = lib.mkOption {
          type = types.str;
          default = "${config.packageName}-cpp";
        };
        src = lib.mkOption {
          type = types.str;
          default = "${config.packageName}-src";
        };
        fileDescriptorSet = lib.mkOption {
          type = types.str;
          default = "${config.packageName}-file-descriptor-set";
        };
      };
    };
  };
  config = lib.mkIf cfg.enable {
    subprojects = {
      ${cfg.subprojectNames.src} =
        { ... }:
        {
          callPackageFunction = { ... }: protoSrc;
        };
      ${cfg.subprojectNames.fileDescriptorSet} =
        { config, ... }:
        {
          callPackageFunction =
            { pkgs, stdenvNoCC, ... }:
            stdenvNoCC.mkDerivation {
              inherit (config) name;
              src = protoSrc;
              nativeBuildInputs = [ pkgs.protobuf ];

              installPhase = ''
                ${protoc} --include_imports --include_source_info --descriptor_set_out=$out
              '';
            };
        };
      ${cfg.subprojectNames.generatedSources.cpp} =
        { config, ... }:
        {
          callPackageFunction =
            let
              # Turn the file path into a python module name, e.g. "foo/bar.proto" -> "foo.pb.cc"
              srcFiles = builtins.map (builtins.replaceStrings [ ".proto" ] [ ".pb.cc" ]) relativeProtoPaths;
              # Turn the file path into a python module name, e.g. "foo/bar.proto" -> "foo.pb.h"
              headerFiles = builtins.map (builtins.replaceStrings [ ".proto" ] [ ".pb.h" ]) relativeProtoPaths;
              pathsInSrcDirectory = lib.concatMapStringsSep " " (file: "src/" + file);
            in
            { pkgs, stdenvNoCC, ... }:
            let
              extraPackages = (cfg.cpp.extraDependencies pkgs);
            in
            stdenvNoCC.mkDerivation {
              inherit (config) name;
              src = protoSrc;
              nativeBuildInputs = [ pkgs.protobuf ];

              cmakeLists = ''
                PROJECT(${subprojects.cpp.packageName})
                CMAKE_MINIMUM_REQUIRED (VERSION 3.24)

                set(PROTO_HEADER ${pathsInSrcDirectory headerFiles})
                set(PROTO_SRC ${pathsInSrcDirectory srcFiles})

                find_package(protobuf CONFIG REQUIRED)
                add_library(${subprojects.cpp.packageName} SHARED ''${PROTO_HEADER} ''${PROTO_SRC})
                target_link_libraries(${subprojects.cpp.packageName}
                  PUBLIC
                    protobuf::libprotobuf
                    ${lib.concatMapStringsSep " " (package: package.name) extraPackages}
                )
                target_include_directories(${subprojects.cpp.packageName} PUBLIC src/)

                ${lib.optionalString cfg.grpc.enable ''
                  find_package(gRPC CONFIG REQUIRED)
                  message(STATUS "Using gRPC ''${gRPC_VERSION}")
                  target_link_libraries(${subprojects.cpp.packageName}
                    PUBLIC
                      gRPC::grpc++
                  )
                ''}

                install(DIRECTORY ./src/ DESTINATION "include/" FILES_MATCHING PATTERN "*.pb.h")
                install(TARGETS ${subprojects.cpp.packageName} LIBRARY DESTINATION "lib/")
              '';

              passAsFile = [ "cmakeLists" ];

              installPhase = ''
                mkdir -p $out/src
                cp "$cmakeListsPath" $out/CMakeLists.txt
                ${protoc} \
                  --cpp_out=$out/src \
                  ${lib.optionalString cfg.grpc.enable "--plugin=protoc-gen-grpc_cpp=${pkgs.grpc}/bin/grpc_cpp_plugin --grpc_cpp_out=$out/src"}
              '';
            };
        };
      ${cfg.subprojectNames.cpp} =
        { config, ... }:
        {
          languages.cpp = {
            callPackageFunction =
              { pkgs, stdenv, ... }:
              stdenv.mkDerivation {
                name = config.packageName;
                src = subprojects.generatedSources.cpp.package;

                nativeBuildInputs = [ pkgs.cmake ];

                buildInputs =
                  [ pkgs.protobuf ]
                  ++ (lib.optionals cfg.grpc.enable [
                    pkgs.grpc
                    pkgs.openssl
                  ])
                  ++ (cfg.cpp.extraDependencies pkgs);
              };
          };
        };
      ${cfg.subprojectNames.generatedSources.python} =
        { config, ... }:
        let
          pyproject = {
            project = {
              name = subprojects.python.name;
              version = "0.1.0";
              description = "Generated protobuf bindings for ${subprojects.python.name}";
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
          pyprojectSettingsFormat = toolsPkgs.formats.toml { };
          pyprojectConfigFile = pyprojectSettingsFormat.generate "pyproject.toml" pyproject;
        in
        {
          callPackageFunction =
            { pkgs, stdenvNoCC, ... }:
            stdenvNoCC.mkDerivation {
              inherit (config) name;
              src = protoSrc;

              nativeBuildInputs = [
                pkgs.protobuf
                toolsPkgs.mypy-protobuf
              ];

              installPhase = ''
                mkdir -p $out/src
                ${protoc} \
                  --python_out=$out/src --mypy_out=$out/src \
                  ${lib.optionalString cfg.grpc.enable "--plugin=protoc-gen-grpc_python=${pkgs.grpc}/bin/grpc_python_plugin --grpc_python_out=$out/src --mypy_grpc_out=$out/src"}
                ${lib.optionalString cfg.grpc.enable ''
                  # Create type aliases in the *_grpc.py files to correspond to the 
                  # aliases created in the *_grpc.pyi files. Without this, these type aliases only
                  # exist at type checking time, and trying to reference those types except in quotation marks
                  # will cause a runtime failure.
                  # For example, without this, the code:
                  #   stub: greeter_pb2_grpc.GreeterServiceAsyncStub = ...
                  # will fail but
                  #   stub: "greeter_pb2_grpc.GreeterServiceAsyncStub" = ...
                  # will succeed. We want to use the *AsyncStub types, but also want the convenience of
                  # just referencing them without quotes. This logic below just creates the *AsyncStub variables in the
                  # *_pb2_grpc.py files as type aliases for the *Stub classes.
                  for grpc_proto in $(find $out/src -name '*_grpc.py'); do
                    sed -i -e '/import grpc/a import typing' $grpc_proto
                    echo >> $grpc_proto
                    for grpc_stub in $(grep -E --only-matching '\w+Stub' $grpc_proto); do
                      echo "''${grpc_stub/%Stub/AsyncStub}: typing.TypeAlias = ''${grpc_stub}" >> $grpc_proto
                    done
                  done
                ''}
                find $out -name '*.py' -execdir touch __init__.py py.typed \;
                cp ${pyprojectConfigFile} $out/pyproject.toml
              '';
            };
        };
      ${cfg.subprojectNames.python} =
        { config, ... }:
        {
          mkShell.nativeBuildInputs = [ config.languages.python.package ];
          languages.python = {
            callPackageFunction =
              let
                # Turn the file path into a python module name, e.g. "foo/bar.proto" -> "foo.bar_pb2"
                protobufPythonModules = builtins.map (builtins.replaceStrings
                  [ ".proto" "/" ]
                  [ "_pb2" "." ]
                ) relativeProtoPaths;
                # Turn the file path into a python module name, e.g. "foo/bar.proto" -> "foo.bar_pb2_grpc"
                grpcPythonModules = builtins.map (builtins.replaceStrings
                  [ ".proto" "/" ]
                  [ "_pb2_grpc" "." ]
                ) relativeProtoPaths;
              in
              { pythonPackages }:
              pythonPackages.buildPythonPackage {
                inherit (config) name;
                pyproject = true;
                src = subprojects.generatedSources.python.package;

                # Validate that all generated protobuf files are importable
                pythonImportsCheck = protobufPythonModules ++ (lib.optionals cfg.grpc.enable grpcPythonModules);

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
        };
    };
  };
}
