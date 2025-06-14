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

  protoSrc =
    (lib.fileset.toSource {
      root = cfg.src;
      fileset = protoFileset;
    }).outPath;

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
      cpp =
        let
          dependencySubmodule = types.submodule {
            options = {
              package = lib.mkOption { type = types.package; };
              packageName = lib.mkOption {
                type = types.nullOr types.str;
                default = null;
              };
              protobufLibraryNames = lib.mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
              grpcLibraryNames = lib.mkOption {
                type = types.listOf types.str;
                default = [ ];
              };
            };
          };
        in
        {
          extraDependencies = lib.mkOption {
            description = ''
              A function from `pkgs` to a list of additional dependencies
              for the generated C++ library.
            '';
            type = types.functionTo (types.listOf dependencySubmodule);
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
              # Turn the protobuf file path into a .pb.cc filename, e.g. "foo/bar.proto" -> "foo.pb.cc"
              srcFiles = builtins.map (builtins.replaceStrings [ ".proto" ] [ ".pb.cc" ]) relativeProtoPaths;
              # Turn the protobuf file path into a .pb.h filename, e.g. "foo/bar.proto" -> "foo.pb.h"
              headerFiles = builtins.map (builtins.replaceStrings [ ".proto" ] [ ".pb.h" ]) relativeProtoPaths;
              # Turn the protobuf file path into a .grpc.pb.cc filename, e.g. "foo/bar.proto" -> "foo.grpc.pb.cc"
              grpcSrcFiles = builtins.map (builtins.replaceStrings
                [ ".proto" ]
                [ ".grpc.pb.cc" ]
              ) relativeProtoPaths;
              # Turn the protobuf file path into a .grpc.pb.h filename, e.g. "foo/bar.proto" -> "foo.grpc.pb.h"
              grpcHeaderFiles = builtins.map (builtins.replaceStrings
                [ ".proto" ]
                [ ".grpc.pb.h" ]
              ) relativeProtoPaths;
              pathsInSrcDirectory = lib.concatMapStringsSep " " (file: "src/" + file);
            in
            { pkgs, stdenvNoCC, ... }:
            let
              extraDependencies = (cfg.cpp.extraDependencies pkgs);
            in
            stdenvNoCC.mkDerivation {
              inherit (config) name;
              src = protoSrc;
              nativeBuildInputs = [ pkgs.protobuf ];

              # This CMake package produces 2-3 libraries:
              # * libfoo-cpp-proto: the protobuf C++ bindings (only)
              # * (optionally) libfoo-cpp-grpc: The gRPC C++ bindings (links against libfoo-cpp-proto)
              # * libfoo-cpp: An empty library that links against both libfoo-cpp-grpc (if present) and libfoo-cpp-proto for simplicity
              #   and backwards-compatibility
              cmakeLists = ''
                CMAKE_MINIMUM_REQUIRED (VERSION 3.24)
                PROJECT(${subprojects.cpp.packageName})

                set(PROTO_HEADER ${pathsInSrcDirectory headerFiles})
                set(PROTO_SRC ${pathsInSrcDirectory srcFiles})

                find_package(protobuf CONFIG REQUIRED)
                ${lib.pipe extraDependencies [
                  (builtins.filter (dependency: dependency.packageName != null))
                  (lib.concatMapStringsSep "\n" (dependency: ''
                    find_package(${dependency.packageName} CONFIG REQUIRED)
                  ''))
                ]}
                add_library(${subprojects.cpp.packageName} SHARED ${toolsPkgs.emptyFile})
                set_target_properties(${subprojects.cpp.packageName} PROPERTIES LINKER_LANGUAGE CXX)
                set_target_properties(${subprojects.cpp.packageName} PROPERTIES EXPORT_NAME default)
                install(
                  TARGETS ${subprojects.cpp.packageName}
                  EXPORT ${subprojects.cpp.packageName}-config
                  LIBRARY DESTINATION "lib/"
                )

                add_library(${subprojects.cpp.packageName}-proto SHARED ''${PROTO_HEADER} ''${PROTO_SRC})
                target_link_libraries(${subprojects.cpp.packageName}-proto
                  PUBLIC
                    protobuf::libprotobuf
                    ${lib.concatStringsSep " " (
                      builtins.concatMap (dependency: dependency.protobufLibraryNames) extraDependencies
                    )}
                )
                target_include_directories(
                  ${subprojects.cpp.packageName}-proto
                  PRIVATE src
                  INTERFACE $<INSTALL_INTERFACE:include>
                )
                set_target_properties(${subprojects.cpp.packageName}-proto PROPERTIES EXPORT_NAME proto)
                install(
                  TARGETS ${subprojects.cpp.packageName}-proto
                  EXPORT ${subprojects.cpp.packageName}-config
                  LIBRARY DESTINATION "lib/"
                )

                target_link_libraries(${subprojects.cpp.packageName} PUBLIC ${subprojects.cpp.packageName}-proto)

                ${lib.optionalString cfg.grpc.enable ''
                  set(GRPC_HEADER ${pathsInSrcDirectory grpcHeaderFiles})
                  set(GRPC_SRC ${pathsInSrcDirectory grpcSrcFiles})

                  find_package(gRPC CONFIG REQUIRED)
                  message(STATUS "Using gRPC ''${gRPC_VERSION}")
                  add_library(${subprojects.cpp.packageName}-grpc SHARED ''${GRPC_HEADER} ''${GRPC_SRC})
                  target_link_libraries(${subprojects.cpp.packageName}-grpc
                    PUBLIC
                      gRPC::grpc++
                      ${subprojects.cpp.packageName}-proto
                      ${lib.concatStringsSep " " (
                        builtins.concatMap (dependency: dependency.grpcLibraryNames) extraDependencies
                      )}
                  )
                  target_include_directories(
                    ${subprojects.cpp.packageName}-grpc
                    PRIVATE src
                    INTERFACE $<INSTALL_INTERFACE:include>
                  )
                  set_target_properties(${subprojects.cpp.packageName}-grpc PROPERTIES EXPORT_NAME grpc)
                  install(
                    TARGETS ${subprojects.cpp.packageName}-grpc
                    EXPORT ${subprojects.cpp.packageName}-config
                    LIBRARY DESTINATION "lib/"
                  )

                  target_link_libraries(${subprojects.cpp.packageName} PUBLIC ${subprojects.cpp.packageName}-grpc)
                ''}

                install(
                  EXPORT ${subprojects.cpp.packageName}-config
                  DESTINATION lib/cmake/${subprojects.cpp.packageName}
                  NAMESPACE ${subprojects.cpp.packageName}::
                )
                install(FILES ./${subprojects.cpp.packageName}-config-dependencies.cmake DESTINATION lib/cmake/${subprojects.cpp.packageName}/)
                install(DIRECTORY ./src/ DESTINATION "include" FILES_MATCHING PATTERN "*.pb.h")
              '';

              cmakeFindDependencies = ''
                block()
                  find_dependency(Protobuf)
                  ${lib.pipe extraDependencies [
                    (builtins.filter (dependency: dependency.packageName != null))
                    (lib.concatMapStringsSep "\n" (dependency: ''
                      find_dependency(${dependency.packageName})
                    ''))
                  ]}
                ${lib.optionalString cfg.grpc.enable ''
                  find_dependency(gRPC)
                ''}
                endblock()
              '';

              passAsFile = [
                "cmakeLists"
                "cmakeFindDependencies"
              ];

              installPhase = ''
                mkdir -p $out/src
                cp "$cmakeListsPath" $out/CMakeLists.txt
                cp "$cmakeFindDependenciesPath" $out/${subprojects.cpp.packageName}-config-dependencies.cmake
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

                propagatedBuildInputs =
                  [ pkgs.protobuf ]
                  ++ (lib.optionals cfg.grpc.enable [
                    pkgs.grpc
                    pkgs.openssl
                  ])
                  ++ (builtins.map (dependency: dependency.package) (cfg.cpp.extraDependencies pkgs));

                separateDebugInfo = true;
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
              { python }:
              python.pkgs.buildPythonPackage rec {
                inherit (config) name;
                pyproject = true;
                src = subprojects.generatedSources.python.package;

                # Validate that all generated protobuf files are importable
                pythonImportsCheck = protobufPythonModules ++ (lib.optionals cfg.grpc.enable grpcPythonModules);

                dependencies =
                  (with python.pkgs; [
                    protobuf
                    types-protobuf
                  ])
                  ++ (lib.optionals cfg.grpc.enable (with python.pkgs; [ grpcio ]))
                  ++ (cfg.python.extraDependencies python.pkgs);
                # Legacy attribute
                propagatedBuildInputs = dependencies;

                build-system = [ python.pkgs.hatchling ];
                # Legacy attribute
                nativeBuildInputs = build-system;
              };
          };
        };
    };
  };
}
