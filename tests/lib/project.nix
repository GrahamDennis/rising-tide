# rising-tide flake context
{ risingTideLib, ... }:
let
  inherit (risingTideLib) mkProject;
in
{
  "test defaults" = risingTideLib.tests.filterExprToExpected {
    expr = mkProject { system = "x86_64-linux"; } {
      name = "example-project";
    };
    expected = {
      name = "example-project";
      relativePaths.fromRoot = "./.";
      subprojects = { };
      enabledSubprojectsList = [ ];
      tools.go-task = {
        enable = true;
        taskfile = {
          output.group = {
            begin = "::group::{{.ALIAS}}";
            end = "::endgroup::";
          };
          tasks = {
            "check".cmds = [ { task = "check:treefmt"; } ];
            "check:treefmt" = { };
            "tool:deadnix" = { };
            "tool:nixfmt-rfc-style" = { };
            "tool:shellcheck" = { };
            "tool:shfmt" = { };
            "tool:treefmt" = { };
          };
        };
      };
    };
  };
}
