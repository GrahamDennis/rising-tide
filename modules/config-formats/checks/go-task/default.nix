# rising-tide flake context
{ risingTideLib, ... }:
# rising-tide per-system flake context
{ system, ... }:
let
  mkConfig = risingTideLib.configFormats.go-task system;
in
{
  no-overrides = {
    actual = mkConfig {
      data = {
        tasks.hello = {
          desc = "Say hello";
          cmds = [ "echo Hello World!" ];
        };
      };
    };
    expected = ./example.yml;
  };
}
