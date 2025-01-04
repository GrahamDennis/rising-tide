# rising-tide bootstrap injector context
{
  risingTideLib,
  ...
}:
{
  _module.args = {
    inherit risingTideLib;
  };
}
