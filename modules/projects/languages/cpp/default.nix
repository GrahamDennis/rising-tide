# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{
  config,
  pkgs,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  getCfg = projectConfig: projectConfig.languages.cpp;
  cfg = getCfg config;
  enabledIn = projectConfig: (getCfg projectConfig).enable;
  overrideDerivationRetainingOutput =
    drv: fn:
    let
      overriddenDerivation = lib.overrideDerivation drv fn;
    in
    if drv.outputSpecified or false then
      lib.getOutput drv.outputName overriddenDerivation
    else
      overriddenDerivation;
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
        type = types.nullOr risingTideLib.types.callPackageFunction;
        default = null;
      };

      coverage = {
        enable = lib.mkEnableOption "Enable coverage (in develop shell)";
        package = lib.mkPackageOption toolsPkgs "lcov" { pkgsText = "toolsPkgs"; };
        setupHook = lib.mkOption {
          type = types.package;
          default = pkgs.makeSetupHook {
            name = "coverage-hook";
          } ./hooks/coverage.sh;
        };
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
            enableInDevelopShell = lib.mkEnableOption "Enable ASAN in the develop shell";
            cflags = lib.mkOption {
              type = types.str;
              default = "-fsanitize=address -O1 -fno-omit-frame-pointer -fno-optimize-sibling-calls -fsanitize-recover=address -g";
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
            enableInDevelopShell = lib.mkEnableOption "Enable TSAN in the develop shell";
            cflags = lib.mkOption {
              type = types.str;
              default = "-fsanitize=thread -O2 -fno-omit-frame-pointer -fno-optimize-sibling-calls -g -U_FORTIFY_SOURCE";
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
    (lib.mkIf (cfg.callPackageFunction != null) {
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
              overrideDerivationRetainingOutput drv (prev: {
                name = prev.name + "-with-asan";
                dontStrip = true;
                nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ cfg.sanitizers.asan.setupHook ];
                buildInputs = builtins.map (input: (enableAsan input)) (prev.buildInputs or [ ]);
              });
            enableTsan =
              drv:
              overrideDerivationRetainingOutput (drv.overrideAttrs (_final: _prev: { doCheck = false; })) (prev: {
                name = prev.name + "-with-tsan";
                dontStrip = true;
                nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ cfg.sanitizers.tsan.setupHook ];
                buildInputs = builtins.map (input: (enableTsan input)) (prev.buildInputs or [ ]);
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
    })
    (lib.mkIf cfg.enable {
      mkShell.enable = true;
      mkShell.nativeBuildInputs = [
        (lib.mkIf cfg.sanitizers.asan.enableInDevelopShell (cfg.sanitizers.asan.setupHook))
        (lib.mkIf cfg.sanitizers.tsan.enableInDevelopShell (cfg.sanitizers.tsan.setupHook))
        (lib.mkIf cfg.coverage.enable (cfg.coverage.setupHook))
      ];
      tools.vscode = {
        recommendedExtensions = {
          "ms-vscode.cpptools-extension-pack".enable = true;
          "matepek.vscode-catch2-test-adapter".enable = true;
          "vadimcn.vscode-lldb".enable = true;
          "llvm-vs-code-extensions.vscode-clangd".enable = true;
        };
      };
    })
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allEnabledProjectsList)) {
      # To use CLion with nix, create a new toolchain where the environment file is
      # ./.idea/scripts/env.sh and CMake executable path is ./.idea/scripts/cmake
      # then use this toolchain in the CLion project.
      tools.jetbrains = {
        projectSettings = {
          "misc.xml" = {
            components.CMakePythonSetting.options.pythonIntegrationState = "YES";
            components.CMakeWorkspace.attrs.PROJECT_DIR = "$PROJECT_DIR$";
          };
          "modules.xml" = {
            components.ProjectModuleManager.children = [
              {
                name = "modules";
                children = [
                  {
                    name = "module";
                    attrs.fileurl = "file://$PROJECT_DIR$/.idea/${config.name}-cpp.iml";
                    attrs.filepath = "$PROJECT_DIR$/.idea/${config.name}-cpp.iml";
                  }
                ];
              }
            ];
          };
        };
        moduleSettings."${config.name}-cpp.iml" = {
          type = "CPP_MODULE";
          attrs.classpath = "CMake";
        };
        xml."toolchains.xml" = {
          name = "application";
          children = [
            {
              name = "component";
              attrs.name = "CPPToolchains";
              attrs.version = "9";
              children = [
                {
                  name = "toolchains";
                  attrs.detectedVersion = "5";
                  children = [
                    {
                      name = "toolchain";
                      attrs = {
                        name = "rising-tide-${config.name}";
                        toolSetKind = "SYSTEM_UNIX_TOOLSET";
                        customCmakePath = "@projectAbsolutePath@/.idea/scripts/cmake";
                        debuggerKind = "BUNDLED_LLDB";
                        environment = "@projectAbsolutePath@/.idea/scripts/env.sh";
                      };
                    }
                  ];
                }
              ];
            }
          ];
        };
      };
      tools.gitignore = {
        enable = true;
        rules = "/.idea/toolchains.xml";
      };
      tools.nixago.requests = lib.mkIf config.tools.jetbrains.enable [
        {
          data = ./jetbrains/env.sh;
          output = ".idea/scripts/env.sh";
          hook.mode = "copy";
          hook.extra = ''
            # Substitute the path to direnv
            sed -i -e "s|@direnvPath@|${lib.getExe config.tools.direnv.package}|g" .idea/scripts/env.sh
          '';
        }
        {
          data = ./jetbrains/multicall.sh;
          output = ".idea/scripts/cmake";
          hook.mode = "copy";
          hook.extra = "chmod +x .idea/scripts/cmake";
        }
      ];
    })
  ];
}
