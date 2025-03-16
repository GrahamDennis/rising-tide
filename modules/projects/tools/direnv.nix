# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.direnv;
in
{
  options = {
    tools.direnv = {
      enable = lib.mkEnableOption "Enable direnv integration";
      contents = lib.mkOption {
        type = types.str;
        description = "The contents of the .envrc file to generate";
        default = ''
          if ! has nix_direnv_version || ! nix_direnv_version 3.0.6; then
            source_url "https://raw.githubusercontent.com/nix-community/nix-direnv/3.0.6/direnvrc" "sha256-RYcUJaRMf8oF5LznDrlCXbkOQrywm0HDv1VjYGaJGdM="
          fi

          use flake
        '';
      };
      experimental.dotenv = {
        enable = lib.mkEnableOption "Enable exporting only particular environment variables in .envrc";
        variables = lib.mkOption {
          type = types.listOf types.str;
          description = "The environment variables to export";
          default = [ "PYTHONPATH" ];
        };
      };
      package = lib.mkPackageOption toolsPkgs "direnv" { pkgsText = "toolsPkgs"; };
    };
  };

  config = lib.mkIf cfg.enable {
    tools = {
      gitignore = {
        enable = true;
        rules = ''
          /.direnv
        '';
      };
      nixago.requests = [
        {
          data = toolsPkgs.writeText "envrc" cfg.contents;
          output = ".envrc";
          hook.mode = "copy";
        }
      ];

      vscode = {
        settings = {
          "direnv.path.executable" = lib.getExe cfg.package;
          "direnv.watchForChanges" = false;
        };

        recommendedExtensions."mkhl.direnv".enable = true;
      };
    };
  };
}
