# injector context
{ ... }:
# module context
{ lib, ... }:
let
  inherit (lib) types;
in
{
  options.foo = lib.mkOption {
    type = types.int;
    readOnly = true;
  };
  config.foo = 42;
}
