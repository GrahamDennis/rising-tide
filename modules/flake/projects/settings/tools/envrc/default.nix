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
  ...
}:
let
  inherit (lib) types;
  inherit (flake-parts-lib) mkSubmoduleOptions;
  cfg = config.settings.tools.envrc;
in
{
  options.settings = mkSubmoduleOptions {
    tools.envrc = {
      enable = lib.mkEnableOption "Enable envrc integration";
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
          engine = inputs.nixago.engines.${system}.cue {
            flags = {
              expression = "rendered";
              out = "text";
            };

            files = [ ./envrc.cue ];
          };
        }
      ];
    };

    rootProjectSettings.tools = lib.mkIf cfg.enable {
      vscode.recommendedExtensions = {
        "mkhl.direnv" = true;
      };
    };
  };
}
