# rising-tide flake context
{ ... }:
{
  mkOverlay =
    packagePath: callPackageFunction: final: prev:
    let
      len = builtins.length packagePath;
      atDepth =
        n: final: prev:
        let
          name = builtins.elemAt packagePath n;
        in
        # Leaf: just create the package
        if n == len then
          final.callPackage callPackageFunction { }

        else
          {
            ${name} =
              # If prev doesn't have this attribute, we can just create the attributes from here
              if !(prev ? ${name}) then
                atDepth (n + 1) final { }
              # If overrideScope' exists (removed after NixOS 24.11) use that
              else if prev.${name} ? "overrideScope'" then
                prev.${name}.overrideScope' (atDepth (n + 1))
              # If overrideScope exists, then use that
              else if prev.${name} ? "overrideScope" then
                prev.${name}.overrideScope (atDepth (n + 1))
              # Otherwise perform a recursive merge
              else
                prev.${name} // (atDepth (n + 1) final { });
          };
    in
    atDepth 0 final prev;
}
