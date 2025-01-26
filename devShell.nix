# rising-tide flake context
{
  risingTideLib,
  lib,
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
  batsExe = lib.getExe' batsWithLibraries "bats";
  project = risingTideLib.mkProject { inherit system; } {
    name = "rising-tide-root";
    relativePaths.toRoot = "./.";
    tools = {
      circleci.enable = true;
      cue.enable = true;
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
            dir = "integration-tests/{{.INTEGRATION_TEST}}";
            label = "integration-test:{{.INTEGRATION_TEST}}";
            prefix = "integration-test:{{.INTEGRATION_TEST}}";
            cmds = [
              "nix develop --show-trace --command ${batsExe} ./test.bats"
            ];
          };
          build = {
            deps = [
              "nix-build:project-module-docs"
              "nix-build:lib-docs"
              "nix-build:all-checks"
            ];
          };
          "nix-build:*" = {
            desc = "Build a package with `nix build`";
            vars.PACKAGE = "{{index .MATCH 0}}";
            label = "nix-build:{{.PACKAGE}}";
            prefix = "nix-build:{{.PACKAGE}}";
            cmds = [ "nix build --show-trace --print-build-logs .#{{.PACKAGE}}" ];
          };
          "docs:generate" = {
            cmds = [
              "rm -rf docs/rising-tide/docs/_generated; mkdir -p docs/rising-tide/docs/_generated"
              "nix build -o docs/rising-tide/docs/_generated/modules.flake.project.md .#project-module-docs"
              "nix build -o docs/rising-tide/docs/_generated/lib/ .#lib-docs"
            ];
          };
          "docs:build" = {
            deps = [ "docs:generate" ];
            desc = "Build documentation";
            cmds = [
              ''
                cd docs/rising-tide
                npm install
                npm run build
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
    ])
    ++ project.allTools;
}
