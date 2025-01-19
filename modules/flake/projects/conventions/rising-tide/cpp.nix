# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  enabledIn = projectConfig: projectConfig.languages.cpp.enable;
  ifEnabled = lib.mkIf (enabledIn config);
in
lib.mkMerge [
  {
    tools = ifEnabled {
      clang-format.enable = true;
      clang-tidy.enable = true;
      cmake-format.enable = true;
      cmake.enable = true;
    };
  }
  (lib.mkIf config.isRootProject {
    tools.vscode = lib.mkIf (builtins.any enabledIn config.allProjectsList) {
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
