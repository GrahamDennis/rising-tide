# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  ifEnabled = lib.mkIf config.settings.languages.python.enable;
in
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
  rootProjectSettings.tools.vscode = ifEnabled {
    recommendedExtensions = {
      "jnoortheen.nix-ide" = true;
    };
  };
}
