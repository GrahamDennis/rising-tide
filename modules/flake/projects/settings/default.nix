# rising-tide context
{
  injector,
  ...
}:
# project context
{ ... }:
{
  imports = injector.injectModules [
    ./languages
    ./tools
  ];
}
