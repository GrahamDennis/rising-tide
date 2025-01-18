# rising-tide context
{ lib, inputs, ... }:
# go-task config context
{ config, system, ... }:
let
  inherit (config) pkgs;
  settingsFormat = pkgs.formats.yaml { };
in
{
  options = {
    data = lib.mkOption {
      type = settingsFormat.type;
      default = { };
    };
    configFile = lib.mkOption {
      default =
        inputs.nixago.engines.${system}.cue
          {
            files = [ ./taskfile.cue ];
          }
          {
            inherit (config) data;
            format = "yaml";
            output = "taskfile.yml";
          };
    };
  };
}
