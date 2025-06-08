# rising-tide flake context
{ lib, inputs, ... }:
lib.genAttrs (import inputs.systems) (
  system:
  let
    inherit (lib) types;
    pkgs = inputs.nixpkgs.legacyPackages.${system};
  in
  {
    stripStorePaths =
      src:
      pkgs.runCommand "strip-store-paths" { } ''
        # Replace store paths with a fixed string such that
        # /nix/store/....-name-1.2.3/... -> /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee/...
        # /nix/store/....-foo.xyz -> /nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-foo.xyz
        sed -E \
          -e 's|/nix/store/[0-9a-z]{32}-[-.+_?=0-9a-zA-Z]+/|/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee/|g' \
          -e 's|/nix/store/[0-9a-z]{32}-|/nix/store/eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee-|g' \
          ${src} > $out
      '';
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
