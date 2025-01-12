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
