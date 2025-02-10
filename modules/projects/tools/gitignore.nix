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
  cfg = config.tools.gitignore;
  gitignoreStartLine = "# rising-tide-managed: start";
  gitignoreEndLine = "# rising-tide-managed: end";
  sortedLines = builtins.sort builtins.lessThan (lib.splitString "\n" cfg.lines);
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
    ${builtins.concatStringsSep "\\\n" sortedLines}\
    ${gitignoreEndLine}' .gitignore
  '';
in
{
  options = {
    tools.gitignore = {
      enable = lib.mkEnableOption "Enable managing a section of .gitignore";
      lines = lib.mkOption {
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
    mkShell.nativeBuildInputs = [
      (toolsPkgs.writeShellScript "gitignore-hook" shellHook)
    ];
  };
}
