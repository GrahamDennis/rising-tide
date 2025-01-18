# rising-tide flake context
{ lib, ... }:
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
  builtins.mapAttrs (_name: checks: injector'.inject checks) {
    mypy = ./mypy;
    go-task = ./go-task;
  }
)
