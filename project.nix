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
    mkShell = {
      nativeBuildInputs = with pkgs; [
        batsWithLibraries
        nodejs
        nix-eval-jobs
        nix-fast-build
      ];
    };
    tasks.test.dependsOn = [ "test:integration-tests" ];
    tasks.build.dependsOn = [
      "nix-build:project-module-docs"
      "nix-build:lib-docs"
      "nix-build:all-checks"
    ];
    tools = {
      circleci.enable = true;
      cue.enable = true;
      # The new (2025-03-21) default is `.minimal` but some downstream consumers are using "minimal".
      # Using "minimal" is deprecated and will be removed no earlier than 2025-05-01.
      minimal-flake.generatedDirectories = [
        ".minimal"
        "minimal"
      ];
      nix-unit.enable = true;
      treefmt.config.excludes = [ "integration-tests/**" ];
      go-task = {
        taskfile.tasks = {
          "test:integration-tests" = {
            desc = "Run integration tests";
            dir = "integration-tests";
            vars.INTEGRATION_TESTS.sh = ''
              # Find all integration test directories without a ./ prefix
              find . -name flake.nix -print0 | xargs -0 dirname | grep -v 'minimal' | cut -f2- -d'/'
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
              # Control the environment for test execution as much as possible
              "nix develop -i -k HOME -k PATH -k CI --show-trace --command ${batsExe} ./test.bats"
            ];
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
            dir = "docs/rising-tide";
            cmds = [
              "npm install"
              "npm run build"
            ];
          };
        };
      };
      vscode.recommendedExtensions = {
        "jetmartin.bats".enable = true;
      };
      vscode.settings = {
        "cmake.ignoreCMakeListsMissing" = true;
      };
    };
  };

in
project
