# project context
{
  ...
}:
{
  languages.python = {
    enable = true;
    testRoots = [ ];
    callPackageFunction = import ./package.nix;
  };
}
