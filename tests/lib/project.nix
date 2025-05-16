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
            begin = "{{$colours := splitList \",\" ._GROUP_COLOURS }}{{ index $colours (mod (adler32sum .ALIAS) (len $colours)) }}[BEGIN] {{.ALIAS}}[0m";
            end = "{{$colours := splitList \",\" ._GROUP_COLOURS }}{{ index $colours (mod (adler32sum .ALIAS) (len $colours)) }}[END]   {{.ALIAS}}[0m";
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
