# rising-tide context
{
  injector,
  ...
}:
# project context
{ ... }:
{
  imports = injector.injectModules [
    ./cpp
    ./protobuf.nix
    ./python.nix
  ];
}
