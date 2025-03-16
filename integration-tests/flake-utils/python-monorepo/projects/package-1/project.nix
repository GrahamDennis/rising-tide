# project context
{
  ...
}:
{
  relativePaths.fromParentProject = "projects/package-1";
  languages.python = {
    enable = true;
    callPackageFunction = import ./package.nix;
  };
  tools.coverage-py.config = {
    report.fail_under = 100;
  };
}
