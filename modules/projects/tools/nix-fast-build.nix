# rising-tide flake context
{ lib, ... }:
# project tools context
{
  config,
  toolsPkgs,
  system,
  ...
}:
let
  cfg = config.tools.nix-fast-build;
  nix-fast-buildExe = lib.getExe cfg.package;
in
{
  options = {
    tools.nix-fast-build = {
      enable = lib.mkEnableOption "Enable nix-fast-build integration";
      package = lib.mkPackageOption toolsPkgs "nix-fast-build" { pkgsText = "toolsPkgs"; };
      jobsFlakeAttrPath = lib.mkOption {
        description = "The flake attribute path that contains jobs to build with nix-fast-build";
        type = lib.types.str;
        default = "hydraJobs.${system}";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tasks.build.dependsOn = [ "nix-fast-build:${cfg.jobsFlakeAttrPath}" ];
    tools.go-task = {
      enable = true;
      taskfile.tasks = {
        "nix-fast-build:*" = {
          desc = "Build jobs with nix-fast-build";
          vars.JOBS = "{{index .MATCH 0}}";
          label = "nix-fast-build:{{.JOBS}}";
          prefix = "nix-fast-build:{{.JOBS}}";
          cmds = [
            ''
              ${nix-fast-buildExe} --flake .?submodules=1#{{.JOBS}} \
                --option show-trace true \
                --result-format junit \
                --result-file build/nix-fast-build.xml
            ''
          ];
        };
        "tool:nix-fast-build" = {
          desc = "Run nix-fast-build. Additional CLI arguments after `--` are forwarded";
          cmds = [ "${nix-fast-buildExe} {{.CLI_ARGS}}" ];
        };
      };
    };
  };
}
