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
      contents = lib.mkOption {
        type = types.str;
        description = "The contents of the .envrc file to generate";
        default = ''
          use flake
        '';
      };
      package = lib.mkPackageOption toolsPkgs "direnv" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        nixago.requests = [
          {
            data = toolsPkgs.writeText "envrc" cfg.contents;
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
