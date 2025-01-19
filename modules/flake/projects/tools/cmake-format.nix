# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.cmake-format;
  settingsFormat = toolsPkgs.formats.yaml { };
  configFile = settingsFormat.generate "cmake-format.yaml" cfg.config;
  cmakeFormatExe = lib.getExe cfg.package;
in
{
  options = {
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

  config = lib.mkIf cfg.enable {
    tools = {
      treefmt = {
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
      go-task = {
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
