# rising-tide flake context
{ lib, ... }:
# project context
{
  config,
  ...
}:
let
  inherit (lib) types;
  cfg = config.tools.gitignore;
  gitignoreStartLine = "# rising-tide-managed: start";
  gitignoreEndLine = "# rising-tide-managed: end";
  shellHook = ''
    if ! test -f .gitignore; then
      touch .gitignore
    fi

    if ! grep -qF "${gitignoreStartLine}" .gitignore
    then
      echo -e "\n${gitignoreStartLine}\n${gitignoreEndLine}" >> .gitignore
    fi

    sed -i '/${gitignoreStartLine}/,/${gitignoreEndLine}/c\
    ${gitignoreStartLine}\
    ${builtins.concatStringsSep "\\\n" (lib.splitString "\n" cfg.rules)}\
    ${gitignoreEndLine}' .gitignore
  '';
in
{
  options = {
    tools.gitignore = {
      enable = lib.mkEnableOption "Enable managing a section of .gitignore";
      rules = lib.mkOption {
        type = types.lines;
        default = [ ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    tools.shellHooks = {
      enable = true;
      hooks.gitignore = shellHook;
    };
  };
}
