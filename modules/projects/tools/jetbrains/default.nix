# rising-tide flake context
{
  lib,
  ...
}:
let
  inherit (lib) types;
in
# project context
{
  config,
  toolsPkgs,
  ...
}:
let
  cfg = config.tools.jetbrains;
  xmlElementType = types.submoduleWith {
    modules = [
      {
        options = {
          name = lib.mkOption { type = types.str; };
          attrs = lib.mkOption {
            type = types.attrsOf types.str;
            default = { };
          };
          children = lib.mkOption {
            type = types.listOf xmlElementType;
            default = [ ];
          };
        };
      }
    ];
  };
  xmlFormat = _parameters: {
    type = xmlElementType;
    generate =
      name: value:
      toolsPkgs.stdenvNoCC.mkDerivation {
        inherit name;
        nativeBuildInputs = [ toolsPkgs.libxslt ];

        xmlValue = builtins.toXML value;
        passAsFile = [ "xmlValue" ];

        buildCommand = ''
          xsltproc ${./nix2xml.xslt} "$xmlValuePath" > $out
        '';
      };
  };
in
{
  options = {
    tools.jetbrains = {
      enable = lib.mkEnableOption "Enable JetBrains IDE integration";
      xml = lib.mkOption {
        type = types.attrsOf xmlElementType;
        default = { };
        visible = "shallow";
      };
      xmlFiles = lib.mkOption {
        readOnly = true;
        type = types.attrsOf types.pathInStore;
        default = builtins.mapAttrs (name: xml: (xmlFormat { }).generate name xml) cfg.xml;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    tools.nixago.requests = lib.mapAttrsToList (name: file: {
      data = file;
      output = ".idea/${name}";
      hook.mode = "copy";
    }) cfg.xmlFiles;
  };
}
