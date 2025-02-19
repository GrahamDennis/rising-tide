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
        # prev doesn't have this attribute, so we can just create the package from here
        else if !(prev ? ${name}) then
          { ${name} = atDepth (n + 1) final { }; }
        # prev.${name} is a scoped set of packages, so we will need to override that scope.
        # If overrideScope' exists (removed after NixOS 24.11) use that
        else if prev.${name} ? "overrideScope'" then
          { ${name} = prev.${name}.overrideScope' (atDepth (n + 1)); }
        # If overrideScope exists, then use that
        else if prev.${name} ? "overrideScope" then
          { ${name} = prev.${name}.overrideScope (atDepth (n + 1)); }
        # Otherwise perform a recursive merge
        else
          { ${name} = prev.${name} // (atDepth (n + 1) final { }); };
    in
    atDepth 0 final prev;
}
