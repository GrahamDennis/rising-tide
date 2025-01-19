# rising-tide flake context
{
  lib,
  inputs,
  flake-parts-lib,
  ...
}:
# project context
{
  config,
  system,
  allProjectsList,
  ...
}:
let
  inherit (lib) types;
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.direnv;
in
{
  options.settings = mkSubmoduleOptions {
    tools.direnv = {
      enable = lib.mkEnableOption "Enable direnv integration";
      content = lib.mkOption {
        type = types.str;
        description = "Content of the .envrc file";
        default = ''
          use flake
        '';
      };
    };
  };

  config = {
    settings.tools = {
      nixago.requests = lib.mkIf cfg.enable [
        {
          data = { inherit (cfg) content; };
          output = ".envrc";
          format = "text";
          hook.mode = "copy";
          # FIXME: replace this with a simple file copy
          engine = inputs.nixago.engines.${system}.cue {
            flags = {
              expression = "rendered";
              out = "text";
            };

            files = [ ./envrc.cue ];
          };
        }
      ];

      vscode.recommendedExtensions =
        lib.mkIf
          (
            config.isRootProject
            && (builtins.any (project: project.settings.tools.direnv.enable) allProjectsList)
          )
          {
            "mkhl.direnv" = true;
          };
    };
  };
}
