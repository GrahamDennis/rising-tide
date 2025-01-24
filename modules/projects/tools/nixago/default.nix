# rising-tide flake context
{
  lib,
  inputs,
  risingTideLib,
  ...
}:
let
  inherit (lib) types;
in
# project context
{
  config,
  toolsPkgs,
  system,
  ...
}:
let
  cfg = config.tools.nixago;
in
{
  options = {
    tools.nixago = {
      requests = lib.mkOption {
        description = ''
          The files to generate using [nixago](https://nix-community.github.io/nixago/quick_start.html#generate-a-configuration).

          Each request is a set of arguments to `nixago.lib.make` such that the entire list can be passed to `nixago.lib.makeAll`.
        '';
        # FIXME: Replace the attrs with a submodule with the noop engine as default.
        type = types.listOf (
          types.submodule [
            {
              freeformType = types.anything;
              options.engine = lib.mkOption {
                type = types.functionTo types.pathInStore;
                description = "The engine to use for generating the derivation";
                default = risingTideLib.nixagoEngines.noop;
              };
            }
          ]
        );
        default = [ ];
      };
    };
  };
  config = lib.mkIf (cfg.requests != [ ]) {
    allTools = [
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
