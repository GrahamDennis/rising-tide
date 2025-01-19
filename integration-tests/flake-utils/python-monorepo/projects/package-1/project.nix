{
  config,
  ...
}:
{
  relativePaths.toParentProject = "projects/package-1";
  languages.python = {
    enable = true;
    callPackageFunction = (
      { pythonPackages }:
      pythonPackages.buildPythonPackage rec {
        name = config.name;
        pyproject = true;
        src = ./.;

        # FIXME: These should end up in the dev shell automatically
        optional-dependencies = {
          dev = with pythonPackages; [
            pytest
            pytest-cov
          ];
        };

        nativeCheckInputs = config.allTools ++ (optional-dependencies.dev);

        build-system = with pythonPackages; [ hatchling ];
      }
    );
  };
}
