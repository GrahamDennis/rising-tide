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
      default = toolsPkgs.stdenvNoCC;
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
    shellHook = lib.mkOption {
      type = types.lines;
      default = "";
    };
    package = lib.mkOption {
      type = types.package;
      default =
        let
          coda =
            builtins.replaceStrings
              [ "@bashCompletionPackage@" ]
              [ (builtins.toString toolsPkgs.bash-completion) ]
              (builtins.readFile ./mk-shell-hook.sh);
          projectShell = toolsPkgs.mkShell.override { stdenv = cfg.stdenv; } {
            inherit (cfg) name inputsFrom nativeBuildInputs;
            shellHook = builtins.concatStringsSep "\n" [
              cfg.shellHook
              coda
            ];
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
            shellHook = builtins.concatStringsSep "\n" [
              previousAttrs.shellHook
              projectShell.shellHook
            ];
          });
      defaultText = lib.literalMD "A `pkgs.mkShell` package";
    };
  };
  config = {
    mkShell = {
      shellHook = lib.concatMapStringsSep "\n" (projectConfig: projectConfig.mkShell.shellHook) (
        builtins.filter enabledIn config.enabledSubprojectsList
      );
      inputsFrom = builtins.concatMap (projectConfig: projectConfig.mkShell.inputsFrom) (
        builtins.filter enabledIn config.enabledSubprojectsList
      );
      nativeBuildInputs = builtins.concatMap (projectConfig: projectConfig.mkShell.nativeBuildInputs) (
        builtins.filter enabledIn config.enabledSubprojectsList
      );
      stdenv = lib.mkMerge (
        lib.unique (builtins.map (inputPackage: inputPackage.stdenv) config.mkShell.inputsFrom)
      );
    };
  };
}
