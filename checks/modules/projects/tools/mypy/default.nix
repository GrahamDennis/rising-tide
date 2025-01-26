# rising-tide flake context
{ risingTideLib, ... }:
# rising-tide per-system flake context
{ system, ... }:
let
  mkMypyConfig =
    mypyConfig:
    (risingTideLib.mkProject { inherit system; } {
      name = "example-project";
      conventions.risingTide.enable = false;
      tools.mypy = mypyConfig // {
        enable = true;
      };
    }).tools.mypy.configFile;
in
{
  no-overrides = {
    actual = mkMypyConfig {
      config = {
        pretty = true;
        strict = true;
        warn_return_any = true;
      };
    };
    expected = ./no-overrides.toml;
  };

  perModuleOverrides = {
    actual = mkMypyConfig {
      config = {
        pretty = true;
        strict = true;
        warn_return_any = true;
      };
      perModuleOverrides = {
        "example1.*" = {
          strict = false;
        };
        "mycode.foo.*" = {
          disallow_untyped_defs = false;
        };
      };
    };
    expected = ./perModuleOverrides.toml;
  };
}
