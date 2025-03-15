# rising-tide flake context
{ lib, injector, ... }:
# project context
{
  config,
  toolsPkgs,
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
        packages._all-project-packages = toolsPkgs.linkFarm "all-project-packages" (
          builtins.removeAttrs config.packages [ "_all-project-packages" ]
        );
        tasks.build.dependsOn = [ "nix-build:_all-project-packages" ];
        tasks.ci = {
          dependsOn = [
            "build"
            "check"
            "test"
          ];
        };
        tasks.ci.check-derivation-unchanged.enable = true;
        tasks.ci.check-not-dirty.enable = true;
        mkShell.enable = true;
        tools = {
          # keep-sorted start block=yes
          deadnix.enable = true;
          gitignore = {
            enable = true;
            rules = ''
              # Ignore build outputs from performing a nix-build or `nix build` command
              /result
              /result-*
            '';
          };
          keep-sorted.enable = true;
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
          mdformat.enable = true;
          minimal-flake.enable = true;
          nixfmt-rfc-style.enable = true;
          ripsecrets.enable = true;
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
          taplo = {
            enable = true;
            config.rule = [
              {
                name = "pyproject dependencies";
                include = [ "**/pyproject.toml" ];
                keys = [
                  "project"
                  "build-system"
                ];
                formatting = {
                  reorder_arrays = true;
                };
              }
              {
                name = "pyproject scripts";
                include = [ "**/pyproject.toml" ];
                keys = [ "project.scripts" ];
                formatting = {
                  reorder_keys = true;
                };
              }
            ];
          };
          vscode.recommendedExtensions = {
            "jnoortheen.nix-ide".enable = true;
          };
          vscode.settings = {
            # See https://github.com/nix-community/vscode-nix-ide/pull/417
            "nix.hiddenLanguageServerErrors" = [
              "textDocument/definition"
              "textDocument/documentSymbol"
            ];
          };
          # keep-sorted end
        };
      };
}
