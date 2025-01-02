# rising-tide flake context
{
  self,
  risingTideBootstrapLib,
  ...
}: {
  _module.args = {
    inherit risingTideBootstrapLib;
    risingTideLib = self.lib;
  };
}
