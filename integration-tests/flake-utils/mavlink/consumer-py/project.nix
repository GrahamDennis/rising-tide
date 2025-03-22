# project context
{
  ...
}:
{
  languages.python = {
    enable = true;
    callPackageFunction = import ./package.nix;
    testRoots = [ ];
  };
}
