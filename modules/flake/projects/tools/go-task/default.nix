# rising-tide context
{
  lib,
  inputs,
  ...
}:
# project tools context
{
  config,
  pkgs,
  system,
  ...
}: let
  cfg = config.go-task;
  yamlFormat = pkgs.formats.yaml {};
  wrappedPackage = pkgs.writeScriptBin "task" ''
    # Temporary workaround until https://github.com/go-task/task/pull/1974 gets merged
    exec ${cfg.package}/bin/task --concurrency 1 "$@"
  '';
in {
  options.go-task = {
    enable = lib.mkEnableOption "Enable go-task integration";
    package = lib.mkPackageOption pkgs "go-task" {};
    taskfile = lib.mkOption {
      type = yamlFormat.type;
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    # The default output format of interleaved does not do line-buffering. As a result,
    # interleaved terminal codes (e.g. colours) can get mixed up with the output of other
    # terminal codes confusing the terminal.
    go-task.taskfile.output = lib.mkDefault "prefixed";
    nativeCheckInputs = [
      (pkgs.makeSetupHook {
          name = "go-task-setup-hook.sh";
          propagatedBuildInputs = [wrappedPackage];
        }
        ./go-task-setup-hook.sh)
    ];
    nixago.requests = lib.mkIf (cfg.taskfile != {}) [
      {
        data = cfg.taskfile;
        output = "taskfile.yml";
        format = "yaml";
        engine = inputs.nixago.engines.${system}.cue {
          files = [./taskfile.cue];
        };
      }
    ];
  };
}
