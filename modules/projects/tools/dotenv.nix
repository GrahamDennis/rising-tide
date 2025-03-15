# rising-tide flake context
{
  lib,
  ...
}:
# project context
{
  config,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.dotenv;
in
{
  options = {
    tools.dotenv = {
      enable = lib.mkEnableOption "Enable dotenv integration";
      variables = lib.mkOption {
        type = types.listOf types.str;
        description = "The environment variables to export";
        default = [
          # keep-sorted start
          "ASAN_OPTIONS"
          "CMAKE_INCLUDE_PATH"
          "CMAKE_LIBRARY_PATH"
          "LSAN_OPTIONS"
          "NIXPKGS_CMAKE_PREFIX_PATH"
          "NIX_BINTOOLS"
          "NIX_CC"
          "NIX_CFLAGS_COMPILE"
          "NIX_LDFLAGS"
          "PYTHONPATH"
          "XDG_DATA_DIRS"
          # keep-sorted end
        ];
      };
    };
  };

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        tools = {
          direnv = {
            enable = true;
            contents = ''
              dotenv_if_exists ${config.relativePaths.toRoot}/.env
            '';
          };
        };
      }

      (lib.mkIf config.isRootProject {
        mkShell.shellHook = ''
          dotenvHook() {
            DOTENV_TEMP_FILE="$(mktemp)"
            ${lib.concatMapStringsSep "\n" (
              variable: "echo \"${variable}=\${${variable}}\" >> $DOTENV_TEMP_FILE"
            ) cfg.variables}
            mv $DOTENV_TEMP_FILE .env
            unset DOTENV_TEMP_FILE
          }
          postShellHooks+=(dotenvHook)
        '';
        tools = {
          gitignore = {
            enable = true;
            rules = ''
              /.env
            '';
          };
          go-task.taskfile = {
            dotenv = [ ".env" ];
          };
        };
      })
    ]
  );
}
