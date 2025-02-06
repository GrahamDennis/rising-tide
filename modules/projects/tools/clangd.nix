# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.clangd;
  settingsFormat = toolsPkgs.formats.yaml { };
  clangdExe = lib.getExe' cfg.package "clangd";
in
{
  options = {
    tools.clangd = {
      enable = lib.mkEnableOption "Enable clangd integration";
      package = lib.mkPackageOption toolsPkgs "clang-tools" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The clangd YAML file to generate.
          Refer to the [clangd documentation](https://clangd.llvm.org/config).
        '';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "clangd.yaml" cfg.config;
      };
    };
  };

  config = lib.mkMerge [
    {
      tools.clangd.config = {
        CompileFlags.CompilationDatabase = "./build";
      };
    }
    (lib.mkIf cfg.enable {
      mkShell.nativeBuildInputs = [ cfg.package ];
      tools = {
        nixago.requests = [
          {
            data = cfg.configFile;
            output = ".clangd";
          }
        ];
        vscode.settings = {
          "clangd.path" = clangdExe;
        };
      };
    })
  ];
}
