{ lib, ... }:
let
  inherit (lib) types;
in
{
  /**
    Type of a function that...
  */
  callPackageFunction = (types.addCheck types.unspecified builtins.isFunction) // {
    name = "callPackageFunction";
    description = "A function that can be called by callPackage and returns a package";
  };
  subpath = types.str // {
    name = "subpath";
    description = "A relative path";
    merge = loc: defs: lib.path.subpath.normalise (lib.mergeEqualOption loc defs);
  };
  overlay = lib.mkOptionType {
    name = "overlay";
    description = "A package overlay";
    descriptionClass = "noun";
    merge =
      _loc: defs:
      let
        list = lib.options.getValues defs;
      in
      lib.composeManyExtensions list;
    emptyValue = {
      value = _final: _prev: { };
    };
  };
}
