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
              AccessModifierOffset = -3;
              IndentWidth = 4;
            };
          };
          clang-tidy.config = {
            Checks = [
              "abseil-*"
              "bugprone-*"
              "cppcoreguidelines-*"
              "performance-*"
              "modernize-*"
              "readability-*"
            ];
            HeaderFilterRegex = ".*";
            WarningsAsErrors = [
              "bugprone-*"
              "performance-*"
            ];
            CheckOptions = {
              # keep-sorted start
              "cppcoreguidelines-avoid-do-while.IgnoreMacros" = true;
              "readability-identifier-naming.ClassCase" = "CamelCase";
              "readability-identifier-naming.ClassConstantCase" = "CamelCase";
              "readability-identifier-naming.ClassMemberCase" = "camelBack";
              "readability-identifier-naming.ConstantMemberCase" = "CamelCase";
              "readability-identifier-naming.ConstantParameterCase" = "camelBack";
              "readability-identifier-naming.EnumCase" = "CamelCase";
              "readability-identifier-naming.EnumConstantCase" = "CamelCase";
              "readability-identifier-naming.FunctionCase" = "camelBack";
              "readability-identifier-naming.GlobalConstantCase" = "CamelCase";
              "readability-identifier-naming.GlobalVariableCase" = "CamelCase";
              "readability-identifier-naming.LocalConstantCase" = "camelBack";
              "readability-identifier-naming.LocalVariableCase" = "camelBack";
              "readability-identifier-naming.MemberCase" = "camelBack";
              "readability-identifier-naming.MethodCase" = "camelBack";
              "readability-identifier-naming.NamespaceCase" = "lower_case";
              "readability-identifier-naming.PrivateMemberCase" = "CamelCase";
              "readability-identifier-naming.ProtectedMemberCase" = "CamelCase";
              "readability-identifier-naming.PublicMemberCase" = "CamelCase";
              "readability-identifier-naming.StructCase" = "CamelCase";
              "readability-identifier-naming.VariableCase" = "camelBack";
              # keep-sorted end
            };
          };
          cmake-format.config = {
            format.line_width = 120;
          };
          vscode.settings = {
            "cmake.ctest.testExplorerIntegrationEnabled" = false;
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
          # keep-sorted start
          clang-format.enable = true;
          clang-tidy.enable = true;
          clangd.enable = true;
          cmake-format.enable = true;
          cmake.enable = true;
          direnv.enable = true;
          vscode.enable = true;
          vscode.launch = {
            version = "0.2.0";
            configurations = [
              {
                type = "lldb";
                request = "launch";
                name = "Debug";
                args = [ ];
                cwd = "\${workspaceFolder}";
              }
            ];
          };
          # keep-sorted end
        };
      })
    ]
  );
}
