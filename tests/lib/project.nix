# rising-tide flake context
{ risingTideLib, ... }:
let
  inherit (risingTideLib) mkProject;
in
{
  "test defaults" = risingTideLib.tests.filterExprToExpected {
    expr = mkProject "x86_64-linux" {
      name = "example-project";
    };
    expected = {
      name = "example-project";
      relativePaths.toRoot = "./.";
      subprojects = { };
      tools = { };
    };
  };
}
