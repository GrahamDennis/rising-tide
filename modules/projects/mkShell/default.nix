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
    shellHook = lib.mkOption {
      type = types.lines;
      default = "";
    };
    package = lib.mkOption {
      type = types.package;
      default =
        let
          projectShell = toolsPkgs.mkShell.override { stdenv = cfg.stdenv; } {
            inherit (cfg)
              name
              inputsFrom
              nativeBuildInputs
              ;
            shellHook =
              let
                coda =
                  builtins.replaceStrings
                    [ "@bashCompletionPackage@" ]
                    [ (builtins.toString toolsPkgs.bash-completion) ]
                    (builtins.readFile ./mk-shell-hook.sh);
              in
              builtins.concatStringsSep "\n" [
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
            shellHook = previousAttrs.shellHook + "\n${projectShell.shellHook}";
          });
      defaultText = lib.literalMD "A `pkgs.mkShell` package";
    };
  };
  config = {
    mkShell = lib.mkMerge [
      {
        shellHook = lib.concatMapStringsSep "\n" (projectConfig: projectConfig.mkShell.shellHook) (
          builtins.filter enabledIn config.subprojectsList
        );
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
