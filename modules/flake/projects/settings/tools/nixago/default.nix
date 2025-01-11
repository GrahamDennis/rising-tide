# rising-tide flake context
{
  lib,
  inputs,
  risingTideLib,
  flake-parts-lib,
  ...
}:
let
  inherit (lib) types;
  inherit (flake-parts-lib) mkSubmoduleOptions;
in
# project context
{
  config,
  toolsPkgs,
  system,
  ...
}:
let
  cfg = config.settings.tools.nixago;
in
{
  options.settings = mkSubmoduleOptions {
    tools.nixago = {
      requests = lib.mkOption {
        description = ''
          The files to generate using [nixago](https://nix-community.github.io/nixago/quick_start.html#generate-a-configuration).

          Each request is a set of arguments to `nixago.lib.make` such that the entire list can be passed to `nixago.lib.makeAll`.
        '';
        type = types.listOf types.attrs;
        default = [ ];
      };
    };
  };
  config = {
    allTools = lib.mkIf (cfg.requests != [ ]) [
      (
        let
          bashSafeName = risingTideLib.sanitizeBashIdentifier "project${config.relativePaths.toRoot}SetupHook";
        in
        toolsPkgs.makeSetupHook {
          name = "${config.relativePaths.toRoot}-setup-hook";
          substitutions = {
            inherit bashSafeName;
            relativePathToRoot = config.relativePaths.toRoot;
            nixagoHook =
              toolsPkgs.writeShellScript "nixago-setup-hook"
                (inputs.nixago.lib.${system}.makeAll cfg.requests).shellHook;
            bashCompletionPackage = toolsPkgs.bash-completion;
          };
        } ./mk-config-hook.sh
      )
    ];
  };
}
