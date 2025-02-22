{
  description = "Minimal flake interface to rising-tide";

  outputs =
    { self }:
    let
      flakeOutputs = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
    in
    {
      inherit (flakeOutputs)
        devShells
        debug
        modules
        project
        lib
        overlays
        packages
        ;
    };
}
