# rising-tide flake context
{ lib, ... }:
let
  isSimpleAttrs = value: builtins.isAttrs value && !lib.isDerivation value;
  recursivelyMerge =
    lhs: rhs:
    builtins.zipAttrsWith merge [
      lhs
      rhs
    ];
  merge =
    _name: values:
    let
      first = builtins.elemAt values 0;
    in
    if builtins.length values == 1 then
      first
    else
      assert lib.assertMsg (builtins.length values == 2) "There must be at most 2 values to merge";
      let
        second = builtins.elemAt values 1;
      in
      if first ? "overrideScope" then
        first.overrideScope' (_final: prev: recursivelyMerge prev second)
      else if (isSimpleAttrs first && isSimpleAttrs second) then
        recursivelyMerge first second
      else
        second;
in
{
  mkOverlay =
    packagePath: callPackageFunction: final: prev:
    let
      package = (final.callPackage callPackageFunction { });
      namespacedPackage = lib.setAttrByPath packagePath package;
    in
    recursivelyMerge (builtins.intersectAttrs namespacedPackage prev) namespacedPackage;
}
