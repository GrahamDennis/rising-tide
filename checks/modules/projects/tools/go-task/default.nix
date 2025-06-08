# rising-tide flake context
{ risingTideLib, ... }:
# rising-tide per-system flake context
{ system, ... }:
let
  mkGoTaskConfig =
    goTaskConfig:
    risingTideLib.perSystem.${system}.stripStorePaths
      (risingTideLib.mkProject { inherit system; } {
        name = "example-project";
        conventions.risingTide.enable = false;
        tools.go-task = goTaskConfig // {
          enable = true;
        };
      }).tools.go-task.configFile;
in
{
  hello = {
    actual = mkGoTaskConfig {
      taskfile = {
        output = "prefixed";
        tasks.hello = {
          desc = "Say hello";
          cmds = [ "echo Hello World!" ];
        };
      };
    };
    expected = ./hello.yml;
  };
}
