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
  bashSafeName = risingTideLib.sanitizeBashIdentifier "uvShellHook-${config.relativePaths.toRoot}";
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
      tools.shellHooks = {
        enable = true;
        hooks.uv =
          builtins.replaceStrings
            [ "@name@" "@relativePathToRoot@" "@uvExe@" ]
            [ bashSafeName config.relativePaths.toRoot (lib.getExe cfg.package) ]
            (builtins.readFile ./uv-shell-hook.sh);
      };
      tools.vscode = lib.mkIf (!config.isRootProject) {
        settings."python.defaultInterpreterPath" = (
          lib.pipe config.relativePaths.toRoot [
            lib.path.subpath.components
            (builtins.map (_: ".."))
            (components: components ++ [ ".venv/bin/python" ])
            (builtins.concatStringsSep "/")
          ]
        );
      };
    })
  ];
}
