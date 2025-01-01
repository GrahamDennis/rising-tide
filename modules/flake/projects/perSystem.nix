# rising-tide flake context
{lib, ...}: let inherit (lib) types; in
# user project context
{...}:
{
  options = {
    systems = lib.mkOption {
      description = ''
        All the system types the project supports;
      '';
      type = types.listOf types.str;
    };
  };
}