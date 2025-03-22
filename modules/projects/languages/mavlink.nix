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
  cfg = config.languages.mavlink;
  subprojects = lib.mapAttrsRecursive (_path: value: config.subprojects.${value}) cfg.subprojectNames;
in
{
  options = {
    languages.mavlink = {
      enable = lib.mkEnableOption "Enable mavlink language configuration";
      src = lib.mkOption {
        description = ''
          Protobuf sources
        '';
        type = types.path;
      };
      dialectName = lib.mkOption {
        description = ''
          Dialect name for the mavlink protocol
        '';
        type = types.str;
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
      };
    };
  };
  config = lib.mkIf cfg.enable {
    subprojects = {
      ${cfg.subprojectNames.generatedSources.cpp} =
        { config, ... }:
        {
          callPackageFunction =
            { pkgs, ... }:
            pkgs.runCommand config.name
              {
                nativeBuildInputs = [ pkgs.python3Packages.pymavlink ];

                cmakeLists = ''
                  CMAKE_MINIMUM_REQUIRED (VERSION 3.24)
                  PROJECT(${cfg.subprojectNames.cpp})
                  set(CMAKE_VERBOSE_MAKEFILE on)

                  file(GLOB_RECURSE HEADERS *.h *.hpp)

                  find_package(GTest)

                  add_executable(mavlink_tests src/${cfg.dialectName}/gtestsuite.hpp ''${HEADERS})
                  set_target_properties(mavlink_tests PROPERTIES LINKER_LANGUAGE CXX)
                  target_link_libraries(mavlink_tests PRIVATE GTest::gtest_main)

                  include(GoogleTest)
                  gtest_discover_tests(mavlink_tests)

                  # This causes tests to be run by running 'make test' and automatically as part of a nix build.
                  add_custom_target(test COMMAND mavlink_tests)
                  add_dependencies(test mavlink_tests)

                  install(DIRECTORY ./src/ DESTINATION "include/${cfg.subprojectNames.cpp}" FILES_MATCHING PATTERN "*.h" PATTERN "*.hpp")
                '';

                passAsFile = [ "cmakeLists" ];
              }
              ''
                mkdir -p $out/src/
                cp "$cmakeListsPath" $out/CMakeLists.txt
                mavgen.py --wire-protocol 2.0 --lang C++11 \
                  --output=$out/src/ \
                  ${cfg.src}/${cfg.dialectName}.xml
              '';
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
                doCheck = true;
                checkInputs = with pkgs; [ gtest ];

                separateDebugInfo = true;
              };
          };
        };
      ${cfg.subprojectNames.generatedSources.python} =
        { config, ... }:
        let
          pyproject = {
            project = {
              name = cfg.subprojectNames.python;
              version = "0.1.0";
              description = "Generated mavlink bindings for ${cfg.subprojectNames.python}";
              dependencies = [
                "pymavlink"
              ];
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
            { pkgs, ... }:
            pkgs.runCommand config.name
              {
                nativeBuildInputs = [
                  pkgs.python3Packages.pymavlink
                ];
              }
              ''
                mkdir -p $out/src/${cfg.subprojectNames.python}
                mavgen.py --wire-protocol 2.0 --lang Python3 \
                  --output $out/src/${cfg.subprojectNames.python}/__init__ \
                  ${cfg.src}/${cfg.dialectName}.xml
                cp ${pyprojectConfigFile} $out/pyproject.toml
              '';
        };
      ${cfg.subprojectNames.python} =
        { config, ... }:
        {
          languages.python = {
            callPackageFunction =
              { pythonPackages }:
              pythonPackages.buildPythonPackage rec {
                inherit (config) name;
                pyproject = true;
                src = subprojects.generatedSources.python.package;

                # Validate that the generated python is importable
                pythonImportsCheck = [ name ];

                dependencies = with pythonPackages; [
                  pymavlink
                ];
                # Legacy attribute
                propagatedBuildInputs = dependencies;

                build-system = [ pythonPackages.hatchling ];
                # Legacy attribute
                nativeBuildInputs = build-system;
              };
          };
        };
    };
  };
}
