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
      go-task.enable = true;
      shfmt.styleOptions = [
        "--simplify"
        "--indent"
        "2"
        "--case-indent"
        "--binary-next-line"
      ];
    };
  };
  pythonProjectConfig = {
    tools.uv.enable = true;
  };
in
{
  config = lib.mkMerge [
    allProjectsConfig
    (lib.mkIf (project.relativePaths.toRoot == "./.") rootProjectConfig)
    (lib.mkIf (config.python.enable) pythonProjectConfig)
  ];
}
