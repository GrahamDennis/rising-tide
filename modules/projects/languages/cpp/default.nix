# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{ config, pkgs, ... }:
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

      sanitizers =
        let
          asanCfg = cfg.sanitizers.asan;
          lsanCfg = cfg.sanitizers.lsan;
          tsanCfg = cfg.sanitizers.tsan;
        in
        {
          asan = {
            enable = lib.mkEnableOption "Enable package variant with ASAN enabled";
            useInDevelopShell = lib.mkEnableOption "Use this package variant in the develop shell";
            cflags = lib.mkOption {
              type = types.str;
              default = "-fsanitize=address -O1 -fno-omit-frame-pointer -fno-optimize-sibling-calls -g";
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
              default = pkgs.writeTextFile {
                name = "asan-suppressions";
                text = lib.concatLines asanCfg.suppressions;
              };
            };
            setupHook = lib.mkOption {
              type = types.package;
              default = pkgs.makeSetupHook {
                name = "asan-hook";
                substitutions = {
                  asanCflags = asanCfg.cflags;
                  asanOptions = builtins.toString asanCfg.options;
                  lsanOptions = builtins.toString lsanCfg.options;
                };
              } ./hooks/asan.sh;
            };
          };
          lsan = {
            options = lib.mkOption {
              type = types.listOf types.str;
              readOnly = true;
              default = [ "suppressions=${lsanCfg.suppressionsFile}" ] ++ lsanCfg.extraOptions;
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
              default = pkgs.writeTextFile {
                name = "lsan-suppressions";
                text = lib.concatLines lsanCfg.suppressions;
              };
            };
          };
          tsan = {
            enable = lib.mkEnableOption "Enable package variant with TSAN enabled";
            useInDevelopShell = lib.mkEnableOption "Use this package variant in the develop shell";
            cflags = lib.mkOption {
              type = types.str;
              default = "-fsanitize=thread -O2 -fno-omit-frame-pointer -fno-optimize-sibling-calls -g";
            };
            options = lib.mkOption {
              type = types.listOf types.str;
              readOnly = true;
              default = [ "suppressions=${tsanCfg.suppressionsFile}" ] ++ tsanCfg.extraOptions;
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
              default = pkgs.writeTextFile {
                name = "tsan-suppressions";
                text = lib.concatLines tsanCfg.suppressions;
              };
            };
            setupHook = lib.mkOption {
              type = types.package;
              default = pkgs.makeSetupHook {
                name = "tsan-hook";
                substitutions = {
                  tsanCflags = tsanCfg.cflags;
                  tsanOptions = builtins.toString tsanCfg.options;
                };
              } ./hooks/tsan.sh;
            };
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
            enableTsan =
              drv:
              lib.overrideDerivation drv (prev: {
                name = prev.name + "-with-tsan";
                nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ cfg.sanitizers.tsan.setupHook ];
              });
            resultWithExtraPassthru = result.overrideAttrs (prev: {
              passthru = (prev.passthru or { }) // {
                ${if cfg.sanitizers.asan.enable then "withAsan" else null} = enableAsan resultWithExtraPassthru;
                ${if cfg.sanitizers.tsan.enable then "withTsan" else null} = enableTsan resultWithExtraPassthru;
              };
            });
          in
          resultWithExtraPassthru
        );
      packages."${config.packageName}-with-asan" =
        lib.mkIf cfg.sanitizers.asan.enable config.package.passthru.withAsan;
      packages."${config.packageName}-with-tsan" =
        lib.mkIf cfg.sanitizers.tsan.enable config.package.passthru.withTsan;
      mkShell.inputsFrom = lib.mkMerge [
        (lib.mkIf cfg.sanitizers.asan.useInDevelopShell (lib.mkForce [ config.package.passthru.withAsan ]))
        (lib.mkIf cfg.sanitizers.tsan.useInDevelopShell (lib.mkForce [ config.package.passthru.withTsan ]))
      ];
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
