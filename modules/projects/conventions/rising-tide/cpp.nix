# rising-tide flake context
{ lib, injector, ... }:
# project context
{
  config,
  toolsPkgs,
  system,
  ...
}:
let
  cfg = config.conventions.risingTide.cpp;
  cppEnabledIn = projectConfig: projectConfig.languages.cpp.enable;
in
{
  imports = injector.injectModules [ ./common.nix ];
  options.conventions.risingTide.cpp = {
    enable = lib.mkEnableOption "Enable rising-tide C++ conventions";
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      # C++ tool configurations
      {
        conventions.risingTide.common.enable = true;
        languages.cpp.sanitizers = {
          asan = {
            enable = true;
            enableInDevelopShell = true;
          };
          lsan.suppressions = [
            # keep-sorted start
            "leak:PyObject_Malloc"
            "leak:libobjc"
            "leak:libpython3"
            "leak:multiarray_umath.cpython"
            "leak:pybind11"
            "leak:python3"
            # keep-sorted end
          ];
          tsan.enable = true;
        };
        tools = {
          # keep-sorted start block=yes
          clang-format.config = {
            header = {
              BasedOnStyle = "Google";
              ColumnLimit = 120;
            };
          };
          clang-tidy.config = {
            Checks = "bugprone-*,cppcoreguidelines-*";
          };
          cmake-format.config = {
            format.line_width = 120;
          };
          # keep-sorted end
        };
      }
      # Enable C++ tools in C++ projects
      (lib.mkIf (cppEnabledIn config) {
        # Filter because lldb isn't available on aarch64-darwin
        mkShell.nativeBuildInputs = builtins.filter (lib.meta.availableOn { inherit system; }) [
          toolsPkgs.lldb
          toolsPkgs.gdb
        ];
        tools = {
          clangd.enable = true;
          clang-format.enable = true;
          clang-tidy.enable = true;
          cmake-format.enable = true;
          cmake.enable = true;
        };
      })
    ]
  );
}
