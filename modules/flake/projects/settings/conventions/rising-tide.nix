# rising-tide flake context
{ lib, ... }:
# project settings context
{ config, project, ... }:
let
  rootProjectConfig = {
    tools = {
      nixfmt-rfc-style.enable = true;
      shellcheck = {
        enable = true;
        config.external-sources = true;
      };
      treefmt.enable = true;
    };
  };
  allProjectsConfig = {
    tools = {
      go-task.enable = true;
    };
  };
in
{
  config = lib.mkMerge [
    allProjectsConfig
    (lib.mkIf (project.relativePaths.toRoot == "./.") rootProjectConfig)
  ];
}
