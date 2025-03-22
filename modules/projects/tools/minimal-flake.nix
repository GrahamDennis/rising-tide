# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.minimal-flake;
  flakeLock = builtins.toFile "flake.lock" (
    builtins.toJSON {
      nodes = {
        root = { };
      };
      root = "root";
      version = 7;
    }
  );
  flakeNix = builtins.toFile "flake.nix" ''
    {
      description = "Minimal flake interface to ${config.name}";

      outputs =
        { self }:
        let
          flakeOutputs = builtins.getFlake (
            builtins.unsafeDiscardStringContext "path:''${self.sourceInfo}?narHash=''${self.narHash}"
          );
        in
        {
          # The flake output attributes must be explicitly listed so that nix doesn't get into an infinite
          # recursion problem. If the flake outputs produced the attribute `self`, then that would override
          # the default `self` attribute and would make the import above not work. By explicitly listing the
          # attributes here, nix can identify that the `self` attribute must resolve to the usual one and therefore
          # can use it in the import above.
          inherit (flakeOutputs) ${builtins.concatStringsSep " " cfg.exportedAttributes};
        };
    }
  '';
  generateReadme =
    { directory }:
    builtins.toFile "README.md" ''
      # A minimal flake interface for ${config.name}

      This is an experimental minimal flake interface that attempts to provide a solution for ever-growing flake.lock files. Instead of consuming this flake normally with an input like:

      ```nix
      inputs.${config.name}.url = "insert-url-here";
      ```

      Instead use:

      ```nix
      inputs.${config.name}.url = "insert-url-here?dir=${directory}";
      ```

      This is a drop-in replacement, however your flake.lock will only reference this flake,
      and not any of its transitive dependencies. The cost of using the minimal flake interface
      is that downstream flake consumers are not able to override any of the inputs of this flake.

      ## How does this work?

      This subflake simply calls `builtins.getFlake` on the parent flake using the same nix source package
      as the minimal subflake.
    '';
in
{
  options = {
    tools.minimal-flake = {
      enable = lib.mkEnableOption "Generate a minimal flake interface";
      generatedDirectories = lib.mkOption {
        type = types.listOf types.str;
        description = "The directory paths to generate the minimal flake interface to";
        default = [ ".minimal" ];
      };
      exportedAttributes = lib.mkOption {
        type = types.listOf types.str;
        description = "The flake attributes to export";
        default = [
          "overlays"
          "pythonOverlays"
          "packages"
          "legacyPackages"
          "lib"
          "modules"
          "nixosModules"
          "nixosConfigurations"
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      nixago.requests = builtins.concatMap (directory: [
        {
          data = flakeNix;
          output = "${directory}/flake.nix";
          hook.mode = "copy";
        }
        {
          data = flakeLock;
          output = "${directory}/flake.lock";
          hook.mode = "copy";
        }
        {
          data = generateReadme { inherit directory; };
          output = "${directory}/README.md";
          hook.mode = "copy";
        }
      ]) cfg.generatedDirectories;
      treefmt.config.excludes = builtins.concatMap (directory: [
        "${directory}/*"
      ]) cfg.generatedDirectories;
    };
  };
}
