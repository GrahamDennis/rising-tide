# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
{
  settings.tools = lib.mkIf (config.settings.languages.python.enable) {
    mypy.enable = true;
    pytest = {
      enable = true;
      coverage.enable = true;
    };
    ruff.enable = true;
    uv.enable = true;
  };
}
