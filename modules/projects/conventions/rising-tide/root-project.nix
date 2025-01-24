# rising-tide flake context
{ lib, injector, ... }:
# project context
{
  config,
  ...
}:
let
  cfg = config.conventions.risingTide.rootProject;
in
{
  imports = injector.injectModules [ ./common.nix ];
  options.conventions.risingTide.rootProject = {
    enable = lib.mkEnableOption "Enable rising-tide root project conventions";
  };

  config =
    lib.mkIf (config.isRootProject && cfg.enable)
      # Root project tool configurations
      {
        conventions.risingTide.common.enable = true;
        tools = {
          direnv = {
            enable = true;
            contents = ''
              if ! has nix_direnv_version || ! nix_direnv_version 3.0.6; then
                source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.6/direnvrc" "sha256-RYcUJaRMf8oF5LznDrlCXbkOQrywm0HDv1VjYGaJGdM="
              fi

              use flake
            '';
          };
          deadnix.enable = true;
          nixfmt-rfc-style.enable = true;
          lefthook = {
            enable = true;
            config = {
              assert_lefthook_installed = true;
              pre-commit = {
                commands = {
                  check = {
                    run = "${lib.getExe' config.tools.go-task.package "task"} check";
                    stage_fixed = true;
                  };
                };
              };
            };
          };
          shellcheck.enable = true;
          shfmt = {
            enable = true;
            printerFlags = [
              "--simplify"
              "--indent"
              "2"
              "--case-indent"
              "--binary-next-line"
            ];
          };
          vscode.recommendedExtensions = {
            "jnoortheen.nix-ide" = true;
          };
        };
      };
}
