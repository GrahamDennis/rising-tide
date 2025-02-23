{
  name = "python-package";
  languages.python.enable = true;
  languages.python.callPackageFunction = import ./package.nix;
}
