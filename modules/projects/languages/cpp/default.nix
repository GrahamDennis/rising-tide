# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{ config, toolsPkgs, ... }:
let
  inherit (lib) types;
  getCfg = projectConfig: projectConfig.languages.cpp;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
in
{
  options = {
    languages.cpp = {
      enable = lib.mkEnableOption "Enable C++ package configuration";
      callPackageFunction = lib.mkOption {
        description = ''
          The function to call to build the C++ package. This is expected to be called like:

          ```
          pkgs.callPackage callPackageFunction {}
          ```
        '';
        type = risingTideLib.types.callPackageFunction;
      };

      sanitizers.asan =
        let
          asanCfg = cfg.sanitizers.asan;
        in
        {
          enable = lib.mkEnableOption "Enable package variant with ASAN enabled";
          cflags = lib.mkOption {
            type = types.str;
            default = "-fsanitize=address -O1 -fno-omit-frame-pointer -fno-optimize-sibling-calls";
          };
          options = lib.mkOption {
            type = types.listOf types.str;
            readOnly = true;
            default = [ "suppressions=${asanCfg.suppressionsFile}" ] ++ asanCfg.extraOptions;
          };
          extraOptions = lib.mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          suppressions = lib.mkOption {
            type = types.listOf types.str;
            default = [ ];
          };
          suppressionsFile = lib.mkOption {
            type = types.pathInStore;
            default = toolsPkgs.writeTextFile {
              name = "asan-suppressions";
              text = lib.concatLines asanCfg.suppressions;
            };
          };
          setupHook = lib.mkOption {
            type = types.package;
            default = toolsPkgs.makeSetupHook {
              name = "asan-hook";
              substitutions = {
                asanCflags = asanCfg.cflags;
                asanOptions = builtins.toString asanCfg.options;
              };
            } ./hooks/asan.sh;
          };
        };
    };
  };
  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      callPackageFunction =
        let
          f = cfg.callPackageFunction;
          # Creates a functor with the same arguments as f
          mirrorArgs = lib.mirrorFunctionArgs f;
        in
        mirrorArgs (
          origArgs:
          let
            result = f origArgs;
            enableAsan =
              drv:
              lib.overrideDerivation drv (prev: {
                name = prev.name + "-with-asan";
                nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ cfg.sanitizers.asan.setupHook ];
              });
            resultWithExtraPassthru = result.overrideAttrs (prev: {
              passthru = (prev.passthru or { }) // {
                ${if cfg.sanitizers.asan.enable then "withAsan" else null} = enableAsan resultWithExtraPassthru;
              };
            });
          in
          resultWithExtraPassthru
        );
      packages."${config.packageName}-with-asan" =
        lib.mkIf cfg.sanitizers.asan.enable config.package.passthru.withAsan;
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.vscode = {
        recommendedExtensions = {
          "ms-vscode.cpptools-extension-pack" = true;
          "matepek.vscode-catch2-test-adapter" = true;
          "vadimcn.vscode-lldb" = true;
          "llvm-vs-code-extensions.vscode-clangd" = true;
        };
      };
    })
  ];
}
