# rising-tide flake context
{ lib, inputs, ... }:
# project context
{
  config,
  system,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.cue-schema;
  cueSchemaExe = lib.getExe cfg.package;
in
{
  options = {
    tools.cue-schema = {
      enable = lib.mkEnableOption "Enable cue-schema tool";
      baseGitRef = lib.mkOption {
        type = types.str;
        # FIXME: Should this be shared with buf-breaking?
        default = "origin/main";
      };
      package = lib.mkPackageOption (inputs.cue-schema.packages.${system}) "cue-schema" {
        pkgsText = "cueSchemaPkgs";
      };
      schemaFlakeAttrPath = lib.mkOption {
        description = "The flake attribute path that contains the generated CUE schema";
        type = lib.types.str;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (cfg.enable) {
      tasks.test.dependsOn = [ "test:cue-schema-breaking" ];
      tools.go-task.taskfile.tasks = {
        "cue-schema-breaking:merge-base" = {
          vars.GIT_MERGE_BASE.sh = "git merge-base ${cfg.baseGitRef} HEAD";
          cmds = [
            "rm -f build/cue-schema-breaking/merge-base.cue"
            {
              cmd = ''
                nix build \
                  '.?submodules=1&rev={{.GIT_MERGE_BASE}}#${cfg.schemaFlakeAttrPath}' \
                  -o build/cue-schema-breaking/merge-base.cue
              '';
              ignore_error = true;
            }
          ];
        };
        "cue-schema-breaking:current" = {
          cmds = [
            "nix build '.?submodules=1#${cfg.schemaFlakeAttrPath}' -o build/cue-schema-breaking/current.cue"
          ];
        };
        "test:cue-schema-breaking" = {
          deps = [
            "cue-schema-breaking:merge-base"
            "cue-schema-breaking:current"
          ];
          desc = "Ensure that there are no breaking changes in the CUE schema";
          cmds = [
            ''
              if [ ! -L build/cue-schema-breaking/merge-base.cue ]; then
                echo "Skipping breaking change detection: cannot find previous CUE schema to compare against."
                exit 0
              fi
              ${cueSchemaExe} breaking \
                --old build/cue-schema-breaking/merge-base.cue \
                --new build/cue-schema-breaking/current.cue
            ''
          ];
        };
      };
    })
  ];
}
