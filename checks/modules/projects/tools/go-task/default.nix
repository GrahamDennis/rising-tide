# rising-tide flake context
{ lib, risingTideLib, ... }:
# rising-tide per-system flake context
{ system, ... }:
let
  mkGoTaskConfig =
    goTaskConfig:
    (risingTideLib.mkProject system {
      name = "example-project";
      conventions.risingTide.enable = lib.mkForce false;
      tools.go-task = goTaskConfig // {
        enable = true;
      };
    }).tools.go-task.configFile;
in
{
  example = {
    actual = mkGoTaskConfig {
      taskfile = {
        output = "prefixed";
        tasks.hello = {
          desc = "Say hello";
          cmds = [ "echo Hello World!" ];
        };
      };
    };
    expected = ./example.yml;
  };
}
