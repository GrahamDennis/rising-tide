# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  enabledIn = projectConfig: projectConfig.settings.languages.python.enable;
  ifEnabled = lib.mkIf (enabledIn config);
in
lib.mkMerge [
  {
    settings.tools = ifEnabled {
      mypy.enable = true;
      pytest = {
        enable = true;
        coverage.enable = true;
      };
      ruff.enable = true;
      uv.enable = true;
    };
  }
  (lib.mkIf config.isRootProject {
    settings.tools.vscode = lib.mkIf (builtins.any enabledIn config.allProjectsList) {
      recommendedExtensions = {
        # FIXME: Make this pytest
        # FIXME: This would belong in the pytest config
        "jnoortheen.nix-ide" = true;
      };
    };
  })
]
