# rising-tide flake context
{
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
  project = risingTideLib.mkProject system {
    name = "rising-tide-root";
    relativePaths.toRoot = "./.";
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
                nix develop --no-write-lock-file --show-trace --command ./test.bats
              ''
            ];
          };
          build = {
            desc = "Build all packages";
            deps = [
              "build:project-module-docs"
              "build:lib-docs"
            ];
          };
          "build:*" = {
            desc = "Build a package";
            vars.PACKAGE = "{{index .MATCH 0}}";
            label = "build:{{.PACKAGE}}";
            prefix = "build:{{.PACKAGE}}";
            cmds = [ "nix build --show-trace .#{{.PACKAGE}}" ];
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
  nixdocFlake = builtins.getFlake "github:nix-community/nixdoc?rev=5a469fe9dbb1deabfd16efbbe68ac84568fa0ba7";
  nixdoc = nixdocFlake.packages.${system}.default;
in
pkgs.mkShell {
  name = "rising-tide-root";
  nativeBuildInputs =
    (with pkgs; [
      nix-unit
      batsWithLibraries
      nodejs

      # Temporary until documentation generation is handled as a package.
      nixdoc
    ])
    ++ project.allTools;
}
