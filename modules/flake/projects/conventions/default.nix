# rising-tide flake context
{ injector, ... }:
# project context
{
  ...
}:
{
  imports = injector.injectModules [ ./rising-tide ];
}
