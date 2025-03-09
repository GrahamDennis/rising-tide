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
  getCfg = projectConfig: projectConfig.mkShell;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
in
{
  options.mkShell = {
    enable = lib.mkEnableOption "Create a dev shell for this project";
    name = lib.mkOption {
      type = types.str;
      default = config.packageName;
      defaultText = lib.literalExpression "config.packageName";
    };
    stdenv = lib.mkOption {
      type = types.package;
      default = toolsPkgs.stdenv;
    };
    inputsFrom = lib.mkOption {
      type = types.listOf types.package;
      default = [ ];
    };
    nativeBuildInputs = lib.mkOption {
      type = types.listOf types.package;
      default = [ ];
    };
    parentShell = lib.mkOption {
      type = types.nullOr types.package;
      default = null;
      description = "mkShell to inherit from";
    };
    package = lib.mkOption {
      type = types.package;
      default =
        let
          projectShell = toolsPkgs.mkShell.override { stdenv = cfg.stdenv; } {
            inherit (cfg) name inputsFrom nativeBuildInputs;
          };
        in
        if cfg.parentShell == null then
          projectShell
        else
          cfg.parentShell.overrideAttrs (previousAttrs: {
            inherit (cfg) name;
            buildInputs = previousAttrs.buildInputs ++ projectShell.buildInputs;
            nativeBuildInputs = previousAttrs.nativeBuildInputs ++ projectShell.nativeBuildInputs;
            propagatedBuildInputs = previousAttrs.propagatedBuildInputs ++ projectShell.propagatedBuildInputs;
            propagatedNativeBuildInputs =
              previousAttrs.propagatedNativeBuildInputs ++ projectShell.propagatedNativeBuildInputs;
          });
      defaultText = lib.literalMD "A `pkgs.mkShell` package";
    };
  };
  config = {
    mkShell = lib.mkMerge [
      {
        inputsFrom = builtins.concatMap (projectConfig: projectConfig.mkShell.inputsFrom) (
          builtins.filter enabledIn config.subprojectsList
        );
        nativeBuildInputs = builtins.concatMap (projectConfig: projectConfig.mkShell.nativeBuildInputs) (
          builtins.filter enabledIn config.subprojectsList
        );
      }
    ];
  };
}
