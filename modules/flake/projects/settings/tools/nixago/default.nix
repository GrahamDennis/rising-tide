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
  project,
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
        type = types.listOf types.attrs;
        default = [ ];
      };
    };
  };
  config = {
    tools.all = lib.mkIf (cfg.requests != [ ]) [
      (
        let
          bashSafeName = risingTideLib.sanitizeBashIdentifier "project${project.relativePaths.toRoot}SetupHook";
        in
        toolsPkgs.makeSetupHook {
          name = "${project.relativePaths.toRoot}-setup-hook";
          substitutions = {
            inherit bashSafeName;
            relativePathToRoot = project.relativePaths.toRoot;
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
