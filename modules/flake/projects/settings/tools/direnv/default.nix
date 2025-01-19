# rising-tide flake context
{
  lib,
  inputs,
  ...
}:
# project context
{
  config,
  system,
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
      content = lib.mkOption {
        type = types.str;
        description = "Content of the .envrc file";
        default = ''
          use flake
        '';
      };
      package = lib.mkPackageOption toolsPkgs "direnv" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkMerge [
    {
      tools = {
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
      tools.vscode = lib.mkIf (builtins.any enabledIn config.allProjectsList) {
        settings."direnv.path.executable" = lib.getExe cfg.package;
        recommendedExtensions."mkhl.direnv" = true;
      };
    })
  ];
}
