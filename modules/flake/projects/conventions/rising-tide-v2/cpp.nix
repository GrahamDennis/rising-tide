# rising-tide flake context
{ lib, injector, ... }:
# project context
{
  config,
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
        tools = {
          clang-format.enable = true;
          clang-tidy.enable = true;
          cmake-format.enable = true;
          cmake.enable = true;
        };
      })
      # Root project configuration when any subproject has C++ enabled
      # FIXME: This belongs in the C++ language module
      (lib.mkIf (config.isRootProject && (builtins.any cppEnabledIn config.allProjectsList)) {
        tools.vscode = {
          recommendedExtensions = {
            "ms-vscode.cpptools-extension-pack" = true;
            "matepek.vscode-catch2-test-adapter" = true;
            "vadimcn.vscode-lldb" = true;
          };
          settings = {
            "cmake.ctest.testExplorerIntegrationEnabled" = false;
          };
        };
      })
    ]
  );
}
