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
    ./python.nix
  ];
}
