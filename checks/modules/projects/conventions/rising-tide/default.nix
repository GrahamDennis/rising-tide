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
        tools.go-task = goTaskConfig;
      }).tools.go-task.configFile;
in
{
  default = {
    actual = mkGoTaskConfig {
    };
    expected = ./taskfile.yml;
  };
}
