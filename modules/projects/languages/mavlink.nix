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
      dialectXml = lib.mkOption {
        description = ''
          MAVLink XML root
        '';
        type = types.path;
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
              }
              ''
                mkdir -p $out/include/${cfg.subprojectNames.generatedSources.cpp}
                mavgen.py --wire-protocol 2.0 --lang C++11 \
                  --output=$out/include/${cfg.subprojectNames.generatedSources.cpp} \
                  ${cfg.dialectXml}
              '';
        };
      ${cfg.subprojectNames.generatedSources.python} =
        { config, ... }:
        let
          pyproject = {
            project = {
              name = subprojects.python.name;
              version = "0.1.0";
              description = "Generated mavlink bindings for ${subprojects.python.name}";
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
                mkdir -p $out/src/${subprojects.python.name}
                mavgen.py --wire-protocol 2.0 --lang Python3 \
                  --output $out/src/${subprojects.python.name}/__init__ \
                  ${cfg.dialectXml}
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
