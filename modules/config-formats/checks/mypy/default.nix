# rising-tide flake context
{ risingTideLib, ... }:
# rising-tide per-system flake context
{ system, ... }:
let
  mkConfig = risingTideLib.configFormats.mypy system;
in
{
  no-overrides = {
    actual = mkConfig {
      data = {
        pretty = true;
        strict = true;
        warn_return_any = true;
      };
    };
    expected = ./no-overrides.toml;
  };
  explicit-overrides = {
    actual = mkConfig {
      data = {
        pretty = true;
        strict = true;
        warn_return_any = true;
        overrides = [
          {
            module = "mycode.foo.*";
            disallow_untyped_defs = false;
          }
        ];
      };
    };
    expected = ./explicit-overrides.toml;
  };

  perModuleOverrides = {
    actual = mkConfig {
      data = {
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
