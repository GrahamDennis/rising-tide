# python packages context
{
  python,
  pkgs,
}:
let
  version = "1.0.0";
in
python.pkgs.buildPythonPackage {
  pname = "clangd-tidy";
  inherit version;
  pyproject = true;

  src = pkgs.fetchFromGitHub {
    owner = "lljbash";
    repo = "clangd-tidy";
    rev = "v${version}";
    hash = "sha256-h6pzMScIODXpA/pF57Sv6SK42Dma0KcqZw1xATTLboY=";
  };

  dependencies = with python.pkgs; [ tqdm ];
  build-system = with python.pkgs; [ setuptools-scm ];
}
