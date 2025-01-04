{
  config,
  ...
}:
{
  relativePaths.toParentProject = "projects/package-1";
  settings.python = {
    enable = true;
    callPackageFunction = (
      { pythonPackages, lib }:
      let
        system = pythonPackages.pkgs.system;
        # Create a filtered src set to reduce rebuilds. This could be replaced with just `./.`
        src = lib.fileset.toSource {
          fileset = files;
          root = ./.;
        };
        files = lib.fileset.unions [
          ./src
          ./tests
          ./pyproject.toml
        ];
      in
      pythonPackages.buildPythonPackage rec {
        name = config.name;
        pyproject = true;
        inherit src;

        # FIXME: These should end up in the dev shell automatically
        optional-dependencies = {
          dev = with pythonPackages; [
            pytest
            pytest-cov
          ];
        };

        nativeCheckInputs = config.tools.${system} ++ (optional-dependencies.dev);

        build-system = with pythonPackages; [ hatchling ];
      }
    );
  };
}
