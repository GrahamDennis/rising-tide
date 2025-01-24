# rising-tide flake context
{
  lib,
  ...
}:
# rising-tide per-system flake context
{ pkgs, injector', ... }:
let
  mkDiffChecks = lib.mapAttrsRecursiveCond (as: !(as ? "actual" && as ? "expected")) (
    _testPath:
    { actual, expected }:
    pkgs.runCommand "diffCheck" { } ''diff --recursive --unified ${expected} ${actual}; touch $out''
  );
in
mkDiffChecks (
  lib.mapAttrsRecursive (_name: checks: injector'.inject checks) {
    modules.projects.tools.go-task = ./modules/projects/tools/go-task;
    modules.projects.tools.mypy = ./modules/projects/tools/mypy;
  }
)
