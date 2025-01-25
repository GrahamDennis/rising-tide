# rising-tide flake context
{ risingTideLib, ... }:
# rising-tide per-system flake context
{ system, pkgs, ... }:
let
  # FIXME: Move this somewhere else... but it's system-specific so it can't obviously go in risingTideLib
  stripStorePaths =
    src:
    pkgs.runCommand "strip-store-paths" { } ''
      # Replace store paths with a fixed string such that
      # /nix/store/....-name-1.2.3/... -> /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee/...
      # /nix/store/....-foo.xyz -> /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-foo.xyz
      sed -E \
        -e 's|/nix/store/[^/ ]+/|/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee/|g' \
        -e 's|/nix/store/[^-/ ]+-|/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g' \
        ${src} > $out
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
