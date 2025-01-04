# rising-tide flake context
{
  inputs,
  risingTideLib,
  ...
}:
# rising-tide perSystem context
{
  pkgs,
  system,
  ...
}:
let
  batsWithLibraries = pkgs.bats.withLibraries (p: [
    p.bats-support
    p.bats-assert
    p.bats-file
  ]);
  project = risingTideLib.mkProject {
    name = "rising-tide-root";
    relativePaths.toRoot = "./.";
    systems = import inputs.systems;
    settings.tools = {
      nix-unit.enable = true;
      go-task = {
        taskfile.tasks = {
          test.deps = [ "test:integration-tests" ];
          "test:integration-tests" = {
            desc = "Run integration tests";
            vars.INTEGRATION_TESTS.sh = ''
              # Find all integration test directories without a ./ prefix
              cd integration-tests;
              find . -name flake.nix -print0 | xargs -0 dirname | cut -f2- -d'/'
            '';
            deps = [
              {
                for = {
                  var = "INTEGRATION_TESTS";
                  split = "\n";
                };
                task = "integration-test:{{.ITEM}}";
              }
            ];
          };
          "integration-test:*" = {
            desc = "Run an integration test";
            vars.INTEGRATION_TEST = "{{index .MATCH 0}}";
            label = "integration-test:{{.INTEGRATION_TEST}}";
            prefix = "integration-test:{{.INTEGRATION_TEST}}";
            cmds = [
              ''
                cd "integration-tests/{{.INTEGRATION_TEST}}"
                nix develop --no-write-lock-file --command ./test.bats
              ''
            ];
          };
          "build" = {
            desc = "Build all packages";
            deps = [ "build:documentation" ];
          };
          "build:*" = {
            desc = "Build a package";
            vars.PACKAGE = "{{index .MATCH 0}}";
            label = "build:{{.PACKAGE}}";
            prefix = "build:{{.PACKAGE}}";
            cmds = [
              ''
                nix build ".#{{.PACKAGE}}"
              ''
            ];
          };
          "ci:check".deps = [
            "check"
            "test"
            "build"
          ];
        };
      };
    };
  };
in
pkgs.mkShell {
  name = "rising-tide-root";
  nativeBuildInputs =
    (with pkgs; [
      nix-unit
      batsWithLibraries
      nodejs
      nixdoc
    ])
    ++ project.tools.${system};
}
