# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.buf;
  settingsFormat = toolsPkgs.formats.yaml { };
  bufExe = lib.getExe cfg.package;
  protobufCfg = config.languages.protobuf;
  protobufImportPaths = protobufCfg.importPaths;
in
{
  options = {
    tools.buf = {
      enable = lib.mkEnableOption "Enable buf tool" // {
        default = cfg.lint.enable || cfg.format.enable;
      };
      lint.enable = lib.mkEnableOption "Enable buf lint tool";
      format.enable = lib.mkEnableOption "Enable buf format tool";
      experimental.breaking = {
        enable = lib.mkEnableOption "Enable buf breaking tool";
      };
      package = lib.mkPackageOption toolsPkgs "buf" { pkgsText = "toolsPkgs"; };
      config = lib.mkOption {
        description = ''
          The buf YAML configuration file (`buf.yaml`) to generate.

          Refer to the [buf documentation](https://buf.build/docs/configuration/v2/buf-yaml/).'';
        type = settingsFormat.type;
        default = { };
      };
      configFile = lib.mkOption {
        type = types.pathInStore;
        default = settingsFormat.generate "buf.yaml" cfg.config;
      };
    };
  };

  config = lib.mkMerge [
    (lib.mkIf cfg.enable {
      tools = {
        buf.config = {
          version = lib.mkDefault "v2";
          modules = lib.mapAttrsToList (name: _src: { path = "./build/buf/${name}"; }) protobufImportPaths;
        };
        treefmt = {
          enable = true;
          config =
            let
              bufLintExe = toolsPkgs.writeShellScript "buf-lint" ''
                set -o errexit
                for file in "$@"; do
                  ${bufExe} lint --config '${cfg.configFile}' "$file"
                done
              '';
              bufFormatExe = toolsPkgs.writeShellScript "buf-format" ''
                set -o errexit
                for file in "$@"; do
                  ${bufExe} format --config '${cfg.configFile}' --write "$file"
                done
              '';
            in
            {
              formatter.buf-lint = lib.mkIf cfg.lint.enable {
                command = bufLintExe;
                includes = [ "*.proto" ];
              };
              formatter.buf-format = lib.mkIf cfg.format.enable {
                command = bufFormatExe;
                includes = [ "*.proto" ];
              };
            };
        };
        go-task = {
          enable = true;
          taskfile.tasks = {
            "check:treefmt".deps = [ "buf:prepare" ];
            "buf:prepare" = {
              desc = "Ensure protobuf imports are available in build/";
              cmds = lib.mapAttrsToList (name: src: ''
                mkdir -p build/buf/
                ln --symbolic --force --no-target-directory ${src} build/buf/${name}
              '') protobufImportPaths;
            };
            "tool:buf" = {
              desc = "Run buf. Additional CLI arguments after `--` are forwarded to buf";
              deps = [ "buf:prepare" ];
              cmds = [ "${bufExe} --config ${cfg.configFile} {{.CLI_ARGS}}" ];
            };
          };
        };
      };
    })
    (lib.mkIf (cfg.enable && cfg.experimental.breaking.enable) {
      tasks.check.dependsOn = [ "check:buf-breaking" ];
      tools.go-task.taskfile.tasks = {
        "buf-breaking:merge-base" = {
          vars.GIT_MERGE_BASE.sh = "git merge-base origin/main HEAD";
          cmds = [
            "rm build/buf-breaking/merge-base.binpb"
            {
              cmd = ''
                nix build \
                  '.?submodules=1&rev={{.GIT_MERGE_BASE}}#${protobufCfg.subprojectNames.fileDescriptorSet}' \
                  -o build/buf-breaking/merge-base.binpb
              '';
              ignore_error = true;
            }
          ];
        };
        "buf-breaking:current" = {
          cmds = [
            "nix build '.?submodules=1#${protobufCfg.subprojectNames.fileDescriptorSet}' -o build/buf-breaking/current.binpb"
          ];
        };
        "check:buf-breaking" = {
          deps = [
            "buf-breaking:merge-base"
            "buf-breaking:current"
          ];
          desc = "Ensure that there are no breaking changes in the proto files";
          cmds = [
            ''
              if [ ! -L build/buf-breaking/merge-base.binpb ]; then
                echo "Skipping breaking change detection: cannot find previous protobufs to compare against."
                exit 0
              fi
              ${bufExe} breaking --config ${cfg.configFile} build/buf-breaking/current.binpb \
                --against build/buf-breaking/merge-base.binpb
            ''
          ];
        };
      };
    })
  ];
}
