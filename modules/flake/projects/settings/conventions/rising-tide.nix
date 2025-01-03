# rising-tide flake context
{ lib, ... }:
# project settings context
{ config, project, ... }:
let
  rootProjectConfig = {
    tools = {
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
      shfmt.enable = true;
      vscode.enable = true;
    };
  };
  allProjectsConfig = {
    tools = {
      shellcheck.config.external-sources = true;
      shfmt.styleOptions = [
        "--simplify"
        "--indent"
        "2"
        "--case-indent"
        "--binary-next-line"
      ];
    };
  };
in
{
  config = lib.mkMerge [
    allProjectsConfig
    (lib.mkIf (project.relativePaths.toRoot == "./.") rootProjectConfig)
  ];
}
