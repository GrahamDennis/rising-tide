# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  pkgs,
  ...
}:
let
  getCfg = projectConfig: projectConfig.tools.experimental.llvm-cov;
  cfg = getCfg config;
  llvm-profdataExe = lib.getExe' cfg.package "llvm-profdata";
  llvm-covExe = lib.getExe' cfg.package "llvm-cov";
in
{
  options = {
    tools.experimental.llvm-cov = {
      enable = lib.mkEnableOption "Enable llvm-cov integration";
      package = lib.mkPackageOption pkgs [ "llvmPackages" "libllvm" ] { };
      coverageTargets = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "The targets to generate coverage data for";
        default = [ ];
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tasks.test.serialTasks = lib.mkAfter [ "test:llvm-cov-report" ];
      tools = {
        go-task = {
          enable = true;
          taskfile = {
            tasks = lib.mkMerge (
              [
                {
                  "llvm-cov:combine" = {
                    desc = "Combine coverage data";
                    cmds = [
                      "${llvm-profdataExe} merge -sparse -o build/default.profdata $(find build -name '*.profraw')"
                    ];
                  };
                  "llvm-cov:report" = {
                    desc = "Report on coverage data";
                    cmds = [
                      "${llvm-covExe} show -instr-profile=build/default.profdata -format=html -output-dir=build/coverage-"
                    ];
                  };
                  "test:llvm-cov-report" = {
                    desc = "Generate a coverage report";
                  };
                }
              ]
              ++ (builtins.map (target: {
                "llvm-cov:report:${target}" = {
                  desc = "Report on coverage data for ${target}";
                  deps = [ "llvm-cov:combine" ];
                  cmds = [
                    ''
                      ${llvm-covExe} show ${target} -instr-profile=build/default.profdata -format=html \
                        -show-line-counts-or-regions \
                        -use-color \
                        -show-instantiation-summary \
                        -show-branches=count \
                        -output-dir=$(dirname ${target})/coverage-report
                      echo "Coverage report generated at $(dirname ${target})/coverage-report/index.html"
                    ''
                    ''
                      ${llvm-covExe} report ${target} -instr-profile=build/default.profdata \
                        -show-region-summary=false \
                        -show-branch-summary=false \
                        -show-branch-summary=false
                    ''
                  ];
                };
                "test:llvm-cov-report".deps = [ "llvm-cov:report:${target}" ];
              }) cfg.coverageTargets)
            );
          };
        };
      };
    })
  ];
}
