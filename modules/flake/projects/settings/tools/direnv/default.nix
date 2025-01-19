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
  enabledIn = projectConfig: projectConfig.settings.tools.direnv.enable;
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

  config = lib.mkMerge [
    {
      settings.tools = {
        nixago.requests = lib.mkIf (enabledIn config) [
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

      };
    }

    (lib.mkIf config.isRootProject {
      settings.tools.vscode.recommendedExtensions =
        lib.mkIf (builtins.any enabledIn config.allProjectsList)
          {
            "mkhl.direnv" = true;
          };

    })
  ];
}
