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
      # Relative paths to build executables / libraries to generate coverage reports for
      "build/tests/dummy_test"
      "build/src/greet"
    ];
  };
}
