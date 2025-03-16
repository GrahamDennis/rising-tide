# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.dotenv;
in
{
  options = {
    tools.dotenv = {
      enable = lib.mkEnableOption "Enable dotenv integration";
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        tools = {
          direnv = {
            enable = true;
            contents = ''
              dotenv_if_exists ${config.relativePaths.toRoot}/.env
            '';
          };
        };
      }

      (lib.mkIf config.isRootProject {
        mkShell.nativeBuildInputs = [
          (toolsPkgs.makeSetupHook {
            name = "dotenv-setup-hook.sh";
            propagatedBuildInputs = [ toolsPkgs.jq ];
          } ./dotenv-setup-hook.sh)
        ];
        tools = {
          gitignore = {
            enable = true;
            rules = ''
              /.env
            '';
          };
          go-task.taskfile = {
            dotenv = [ ".env" ];
          };
        };
      })
    ]
  );
}
