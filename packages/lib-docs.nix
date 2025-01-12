# rising-tide flake context
{
  ...
}:
# pkgs context
{ pkgs }:
let
  system = pkgs.system;
  # FIXME: Remove this once nixdoc > 3.0.8 is available in nixpkgs
  nixdocFlake = builtins.getFlake "github:nix-community/nixdoc?rev=5a469fe9dbb1deabfd16efbbe68ac84568fa0ba7";
  nixdoc = nixdocFlake.packages.${system}.default;

  sources = {
    risingTideLib = {
      attrs = ../lib/attrs.nix;
      injector = ../lib/injector.nix;
      project = ../lib/project.nix;
      strings = ../lib/strings.nix;
      tests = ../lib/tests.nix;
      types = ../lib/types.nix;
    };
  };

in
pkgs.runCommand "lib-docs"
  {
    nativeBuildInputs = [ nixdoc ];
  }
  ''
    mkdir -p $out

    nixdoc --category "" --description "" --prefix "risingTideLib.attrs" --file ${sources.risingTideLib.attrs} > $out/lib.attrs.md
    nixdoc --category "" --description "" --prefix "risingTideLib.injector" --file ${sources.risingTideLib.injector} > $out/lib.injector.md
    nixdoc --category "" --description "" --prefix "risingTideLib.project" --file ${sources.risingTideLib.project} > $out/lib.project.md
    nixdoc --category "" --description "" --prefix "risingTideLib.strings" --file ${sources.risingTideLib.strings} > $out/lib.strings.md
    nixdoc --category "" --description "" --prefix "risingTideLib.tests" --file ${sources.risingTideLib.tests} > $out/lib.tests.md
    nixdoc --category "" --description "" --prefix "risingTideLib.types" --file ${sources.risingTideLib.types} > $out/lib.types.md
  ''
