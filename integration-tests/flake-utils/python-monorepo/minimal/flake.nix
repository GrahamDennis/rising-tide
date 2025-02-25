{
  description = "Minimal flake interface to python-monorepo-root";

  outputs =
    { self }:
    let
      flakeOutputs = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
    in
    {
      # The flake output attributes must be explicitly listed so that nix doesn't get into an infinite
      # recursion problem. If the flake outputs produced the attribute `self`, then that would override
      # the default `self` attribute and would make the import above not work. By explicitly listing the
      # attributes here, nix can identify that the `self` attribute must resolve to the usual one and therefore
      # can use it in the import above.
      inherit (flakeOutputs)
        overlays
        pythonOverlays
        packages
        legacyPackages
        lib
        modules
        nixosModules
        nixosConfigurations
        ;
    };
}
