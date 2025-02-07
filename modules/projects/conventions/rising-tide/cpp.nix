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
        languages.cpp.sanitizers.asan.enable = true;
        tools = {
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
