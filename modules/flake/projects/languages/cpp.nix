# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
# project context
{ config, ... }:
let
  enabledIn = projectConfig: projectConfig.languages.cpp.enable;
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
    };
  };
  config = lib.mkMerge [
    (lib.mkIf (config.isRootProject && (builtins.any enabledIn config.allProjectsList)) {
      tools.vscode = {
        recommendedExtensions = {
          "ms-vscode.cpptools-extension-pack" = true;
          "matepek.vscode-catch2-test-adapter" = true;
          "vadimcn.vscode-lldb" = true;
        };
      };
    })
  ];
}
