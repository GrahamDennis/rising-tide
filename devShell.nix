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
}: let
  batsWithLibraries = pkgs.bats.withLibraries (p: [
    p.bats-support
    p.bats-assert
    p.bats-file
  ]);
  project = risingTideLib.mkProject {
    name = "rising-tide-root";
    relativePaths.toRoot = "./.";
    systems = import inputs.systems;
    perSystem.tools = {
      alejandra.enable = true;
      nix-unit.enable = true;
      go-task = {
        enable = true;
        taskfile.tasks = {
          check.deps = ["check:flake" "check:integration-tests"];
          "check:flake" = {
            desc = "Check flake";
            cmds = ["nix flake check"];
          };
          "check:integration-tests" = {
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
                git clean -fX .
                nix develop --no-write-lock-file --command ./test.bats
              ''
            ];
          };
          "ci:check".deps = ["check"];
        };
      };
      treefmt.enable = true;
    };
  };
in
  pkgs.mkShell {
    name = "rising-tide-root";
    nativeBuildInputs =
      (with pkgs; [nix-unit batsWithLibraries])
      ++ project.tools.${system}.nativeCheckInputs;
  }
