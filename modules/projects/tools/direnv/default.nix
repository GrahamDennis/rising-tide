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

  config = lib.mkIf cfg.enable {
    tools = {
      gitignore = {
        enable = true;
        rules = ''
          /.direnv
        '';
      };
      nixago.requests = [
        {
          data = toolsPkgs.writeText "envrc" cfg.contents;
          output = ".envrc";
          hook.mode = "copy";
        }
      ];

      vscode = {
        settings = {
          "direnv.path.executable" = lib.getExe cfg.package;
          "direnv.watchForChanges" = false;
        };

        recommendedExtensions."mkhl.direnv".enable = true;
      };

    };
  };
}
