{
  name = "cpp-package";
  namespacePath = [
    "rising-tide"
    "integration-tests"
    "cpp"
  ];
  languages.cpp = {
    enable = true;
    callPackageFunction = import ./package.nix;
    coverage.enable = true;
  };
  tools.experimental.llvm-cov = {
    enable = true;
    coverageTargets = [
      "build/tests/dummy_test"
      "build/src/greet"
    ];
  };
}
