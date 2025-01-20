# rising-tide flake context
{ injector, ... }:
{
  imports = injector.injectModules [ ./rising-tide ];
}
