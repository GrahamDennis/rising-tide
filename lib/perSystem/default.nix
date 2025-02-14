# rising-tide flake context
{ lib, inputs, ... }:
lib.genAttrs (import inputs.systems) (
  system:
  let
    inherit (lib) types;
    pkgs = inputs.nixpkgs.legacyPackages.${system};
  in
  {
    formats = {
      xml =
        _parameters:
        let
          elementType = types.submodule {
            options = {
              name = lib.mkOption { type = types.str; };
              attrs = lib.mkOption {
                type = types.attrsOf types.str;
                default = { };
              };
              children = lib.mkOption {
                type = types.listOf elementType;
                default = [ ];
                visible = "shallow";
              };
            };
          };
        in
        {
          type = elementType;
          generate =
            name: value:
            pkgs.stdenvNoCC.mkDerivation {
              inherit name;
              nativeBuildInputs = [ pkgs.libxslt ];

              xmlValue = builtins.toXML value;
              passAsFile = [ "xmlValue" ];

              buildCommand = ''
                xsltproc ${./nix2xml.xslt} "$xmlValuePath" > $out
              '';
            };
        };
    };
  }
)
