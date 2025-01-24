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
  enabledIn = projectConfig: projectConfig.tools.direnv.enable;
  cfg = config.tools.direnv;
in
{
  options = {
    tools.direnv = {
      enable = lib.mkEnableOption "Enable direnv integration";
      configFile = lib.mkOption {
        type = types.path;
        description = "The .envrc file to generate";
        default = ./envrc;
      };
      package = lib.mkPackageOption toolsPkgs "direnv" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        nixago.requests = [
          {
            data = cfg.configFile;
            output = ".envrc";
            hook.mode = "copy";
          }
        ];
      };
    })

    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.vscode = {
        settings = {
          "direnv.path.executable" = lib.getExe cfg.package;
          "direnv.watchForChanges" = false;
        };

        recommendedExtensions."mkhl.direnv" = true;
      };
    })
  ];
}
