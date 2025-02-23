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
  };
}
