# rising-tide flake context
{ risingTideLib, ... }:
let
  inherit (risingTideLib) mkProject;
in
{
  "test defaults" = risingTideLib.tests.filterExprToExpected {
    expr = mkProject {
      name = "example-project";
      systems = [ "x86_64-linux" ];
    };
    expected = {
      name = "example-project";
      relativePaths.toRoot = "./.";
      subprojects = { };
      systems = [ "x86_64-linux" ];
      settings.x86_64-linux = {
        tools = { };
      };
    };
  };
}
