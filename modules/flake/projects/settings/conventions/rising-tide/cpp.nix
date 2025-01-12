# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  ifEnabled = lib.mkIf (config.settings.languages.cpp.enable);
in
{
  settings.tools = ifEnabled {
    clang-format.enable = true;
    cmake-format.enable = true;
    cmake.enable = true;
  };
  rootProjectSettings.tools = ifEnabled {
    vscode = {
      recommendedExtensions = {
        "ms-vscode.cpptools-extension-pack" = true;
        "matepek.vscode-catch2-test-adapter" = true;
        "vadimcn.vscode-lldb" = true;
      };
      settings = {
        "cmake.ctest.testExplorerIntegrationEnabled" = false;
      };
    };
  };
}
