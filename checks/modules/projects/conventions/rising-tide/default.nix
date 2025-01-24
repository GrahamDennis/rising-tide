# rising-tide flake context
{ risingTideLib, ... }:
# rising-tide per-system flake context
{ system, pkgs, ... }:
let
  stripStorePaths =
    src:
    pkgs.runCommand "strip-references" { nativeBuildInputs = [ pkgs.nukeReferences ]; } ''
      cp ${src} $out
      nuke-refs $out
    '';
  mkGoTaskConfig =
    goTaskConfig:
    stripStorePaths
      (risingTideLib.mkProject system {
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
