# project context
{
  ...
}:
{
  relativePaths.fromParentProject = "projects/package-2";
  languages.python = {
    enable = true;
    callPackageFunction = import ./package.nix;
  };
}
