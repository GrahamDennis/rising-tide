# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
{
  rootProjectSettings.tools = lib.mkIf (config.settings.languages.cpp.enable) {
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
