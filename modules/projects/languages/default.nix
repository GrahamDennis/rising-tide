# rising-tide context
{
  injector,
  ...
}:
# project context
{ ... }:
{
  imports = injector.injectModules [
    ./cpp.nix
    ./protobuf.nix
    ./python
  ];
}
