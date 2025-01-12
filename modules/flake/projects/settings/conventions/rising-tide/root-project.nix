# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
{
  settings.tools = lib.mkIf (config.relativePaths.toRoot == "./.") {
    envrc = {
      enable = true;
      content = ''
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
              run = "${lib.getExe' config.settings.tools.go-task.package "task"} check";
              stage_fixed = true;
            };
          };
        };
      };
    };
    shellcheck.enable = true;
    shfmt.enable = true;
    vscode = {
      enable = true;
      settings = {
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "${lib.getExe toolsPkgs.nil}";
      };
      recommendedExtensions = {
        "jnoortheen.nix-ide" = true;
      };
    };
  };
}
