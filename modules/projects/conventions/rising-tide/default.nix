# rising-tide flake context
{ injector, lib, ... }:
# project context
{
  config,
  ...
}:
let
  cfg = config.conventions.risingTide;
in
{
  imports = injector.injectModules [
    ./common.nix
    ./cpp.nix
    ./mavlink.nix
    ./protobuf.nix
    ./python.nix
    ./root-project.nix
  ];
  options.conventions.risingTide = {
    enable = lib.mkEnableOption "Enable rising-tide conventions";
  };

  config = lib.mkIf cfg.enable {
    conventions.risingTide = {
      # keep-sorted start
      common.enable = lib.mkDefault true;
      cpp.enable = lib.mkDefault true;
      mavlink.enable = lib.mkDefault true;
      protobuf.enable = lib.mkDefault true;
      python.enable = lib.mkDefault true;
      rootProject.enable = lib.mkDefault true;
      # keep-sorted end
    };
  };
}
