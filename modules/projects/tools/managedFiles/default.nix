# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.managedFiles;
  managedFileModule = types.submodule (
    { name, ... }:
    {
      options = {
        enable = (lib.mkEnableOption "Enable managed file") // {
          default = true;
        };
        src = lib.mkOption {
          type = types.pathInStore;
          description = "The source file to manage";
        };
        dest = lib.mkOption {
          type = types.str;
          readOnly = true;
          description = "The destination file to manage";
          default = name;
        };
        substitutions = lib.mkOption {
          type = types.attrsOf types.str;
          description = "The substitutions to apply to the source file";
          default = { };
        };
      };
    }
  );
in
{
  options = {
    tools.managedFiles = lib.mkOption {
      type = types.attrsOf managedFileModule;
      default = { };
    };
  };
  config = lib.mkIf (cfg != { }) {
    tools.shellHooks = {
      enable = true;
      hooks.managedFiles = builtins.toString (
        toolsPkgs.writeShellScript "managed-files-setup-hook" (
          lib.concatStringsSep "\n" (
            lib.mapAttrsToList (_name: managedFile: ''
              # FIXME: Check whether the file needs to be overwritten
              cp ${managedFile.src} ${managedFile.dest}
              ${lib.optionalString (managedFile.substitutions != { }) ''
                sed -i -e \
                  ${lib.concatStringsSep " " (
                    lib.mapAttrsToList (key: value: "s'@${key}@' \"${value}\"") managedFile.substitutions
                  )}
              ''}
            '') cfg
          )
        )
      );
    };
  };
}
