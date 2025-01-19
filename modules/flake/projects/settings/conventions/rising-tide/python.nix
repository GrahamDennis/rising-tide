# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  enabledIn = projectConfig: projectConfig.languages.python.enable;
  ifEnabled = lib.mkIf (enabledIn config);
in
lib.mkMerge [
  {
    tools = ifEnabled {
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
    tools.vscode = lib.mkIf (builtins.any enabledIn config.allProjectsList) {
      recommendedExtensions = {
        # FIXME: Make this pytest
        # FIXME: This would belong in the pytest config
        "jnoortheen.nix-ide" = true;
      };
    };
  })
]
