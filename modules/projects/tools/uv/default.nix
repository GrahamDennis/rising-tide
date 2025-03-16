# rising-tide flake context
{
  risingTideLib,
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
  getCfg = projectConfig: projectConfig.tools.uv;
  cfg = getCfg config;
  bashSafeName = risingTideLib.sanitizeBashIdentifier "uvShellHook-${config.relativePaths.fromRoot}";
in
{
  options = {
    tools.uv = {
      enable = lib.mkEnableOption "Enable uv integration";
      package = lib.mkPackageOption toolsPkgs "uv" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools.gitignore = {
        enable = true;
        rules = ''
          # uv virtual environment
          /.venv
        '';
      };
      mkShell.nativeBuildInputs = [
        (toolsPkgs.makeSetupHook {
          name = "uv-shell-hook.sh";
          propagatedBuildInputs = [ cfg.package ];
          substitutions = {
            name = bashSafeName;
            relativePathFromRoot = config.relativePaths.fromRoot;
          };
        } ./uv-shell-hook.sh)
      ];
      tools.vscode = lib.mkIf (!config.isRootProject) {
        settings."python.defaultInterpreterPath" = "${config.relativePaths.toRoot}/.venv/bin/python";
      };
    })
  ];
}
