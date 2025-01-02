# rising-tide flake context
{
  injector,
  lib,
  inputs,
  risingTideLib,
  ...
}: let
  inherit (lib) types;
in
  # project tools context
  {
    config,
    pkgs,
    relativePaths,
    system,
    ...
  }: let
    cfg = config.nixago;
  in {
    options = {
      nixago.requests = lib.mkOption {
        type = types.listOf types.attrs;
        default = [];
      };
    };
    config = {
      nativeCheckInputs = lib.mkIf (cfg.requests != []) [
        (let
          bashSafeName = risingTideLib.sanitizeBashIdentifier "project${relativePaths.toRoot}SetupHook";
        in
          pkgs.makeSetupHook {
            name = "${relativePaths.toRoot}-setup-hook";
            substitutions = {
              inherit bashSafeName;
              relativePathToRoot = relativePaths.toRoot;
              nixagoHook =
                pkgs.writeShellScript "nixago-setup-hook"
                (inputs.nixago.lib.${system}.makeAll cfg.requests).shellHook;
              bashCompletionPackage = pkgs.bash-completion;
            };
          }
          ./mk-config-hook.sh)
      ];
    };
  }
