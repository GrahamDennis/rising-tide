# rising-tide flake context
{ lib, flake-parts-lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.cmake-format;
  settingsFormat = toolsPkgs.formats.yaml { };
  configFile = settingsFormat.generate "cmake-format.yaml" cfg.config;
  cmakeFormatExe = lib.getExe cfg.package;
in
{
  options.settings = mkSubmoduleOptions {
    tools.cmake-format = {
      enable = lib.mkEnableOption "Enable cmake-format integration";
      package = lib.mkPackageOption toolsPkgs "cmake-format" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The cmake-format YAML file to generate.
          Refer to the [cmake-format documentation](https://cmake-format.readthedocs.io/en/latest/configuration.html).
        '';
        type = settingsFormat.type;
        default = { };
      };
    };
  };

  config =
    let
      ifEnabled = lib.mkIf cfg.enable;
    in
    {
      settings.tools = {
        treefmt = ifEnabled {
          enable = true;
          config = {
            formatter.cmake-format = {
              command = cmakeFormatExe;
              options = [
                "--config-files"
                configFile
                "--in-place"
              ];
              includes = [
                "*.cmake"
                "CMakeLists.txt"
              ];
            };
          };
        };
        go-task = ifEnabled {
          enable = true;
          taskfile.tasks = {
            "tool:cmake-format" = {
              desc = "Run cmake-format. Additional CLI arguments after `--` are forwarded to cmake-format";
              cmds = [ "${cmakeFormatExe} --config-files ${configFile} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    };
}
