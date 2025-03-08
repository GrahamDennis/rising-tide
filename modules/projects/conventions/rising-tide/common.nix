# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  cfg = config.conventions.risingTide.common;
in
{
  options.conventions.risingTide.common = {
    enable = lib.mkEnableOption "Enable rising-tide common conventions";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        tools.direnv.contents = ''
          if ! has nix_direnv_version || ! nix_direnv_version 3.0.6; then
            source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.6/direnvrc" "sha256-RYcUJaRMf8oF5LznDrlCXbkOQrywm0HDv1VjYGaJGdM="
          fi

          use flake
        '';
        tools.go-task = {
          taskfile.run = "when_changed";
        };
        tools.shellcheck = {
          config.disable = [ "SC1091" ];
        };
      }
      (lib.mkIf config.isRootProject {
        tools.direnv.enable = true;
        tools.vscode.enable = true;
        tools.jetbrains.enable = true;
      })
    ]
  );
}
