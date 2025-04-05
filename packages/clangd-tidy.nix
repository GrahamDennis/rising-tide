# python packages context
{
  pythonPackages,
  pkgs,
}:
let
  version = "1.0.0";
in
pythonPackages.buildPythonPackage {
  pname = "clangd-tidy";
  inherit version;
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "lljbash";
    repo = "clangd-tidy";
    rev = "v${version}";
    hash = "sha256-h6pzMScIODXpA/pF57Sv6SK42Dma0KcqZw1xATTLboY=";
  };

  dependencies = with pythonPackages; [ tqdm ];
  build-system = with pythonPackages; [ setuptools-scm ];
}
