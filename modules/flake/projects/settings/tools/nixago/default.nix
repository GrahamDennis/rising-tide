# rising-tide flake context
{
  injector,
  lib,
  inputs,
  risingTideLib,
  ...
}:
let
  inherit (lib) types;
in
# project tools context
{
  config,
  toolsPkgs,
  relativePaths,
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
        type = types.listOf types.attrs;
        default = [ ];
      };
    };
  };
  config = {
    tools.all = lib.mkIf (cfg.requests != [ ]) [
      (
        let
          bashSafeName = risingTideLib.sanitizeBashIdentifier "project${relativePaths.toRoot}SetupHook";
        in
        toolsPkgs.makeSetupHook {
          name = "${relativePaths.toRoot}-setup-hook";
          substitutions = {
            inherit bashSafeName;
            relativePathToRoot = relativePaths.toRoot;
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
