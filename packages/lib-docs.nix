# rising-tide flake context
{
  ...
}:
# pkgs context
{ pkgs }:
let

  sources = {
    risingTideLib = {
      attrs = ../lib/attrs.nix;
      injector = ../lib/injector.nix;
      nixagoEngines = ../lib/nixagoEngines.nix;
      overlays = ../lib/overlays.nix;
      project = ../lib/project.nix;
      strings = ../lib/strings.nix;
      tests = ../lib/tests.nix;
      types = ../lib/types.nix;
    };
  };

in
pkgs.runCommand "lib-docs"
  {
    nativeBuildInputs = [ pkgs.nixdoc ];
  }
  ''
    mkdir -p $out

    nixdoc --category "" --description "" --prefix "risingTideLib.attrs" --file ${sources.risingTideLib.attrs} > $out/lib.attrs.md
    nixdoc --category "" --description "" --prefix "risingTideLib.injector" --file ${sources.risingTideLib.injector} > $out/lib.injector.md
    nixdoc --category "" --description "" --prefix "risingTideLib.nixagoEngines" --file ${sources.risingTideLib.nixagoEngines} > $out/lib.nixagoEngines.md
    nixdoc --category "" --description "" --prefix "risingTideLib.overlays" --file ${sources.risingTideLib.overlays} > $out/lib.overlays.md
    nixdoc --category "" --description "" --prefix "risingTideLib.project" --file ${sources.risingTideLib.project} > $out/lib.project.md
    nixdoc --category "" --description "" --prefix "risingTideLib.strings" --file ${sources.risingTideLib.strings} > $out/lib.strings.md
    nixdoc --category "" --description "" --prefix "risingTideLib.tests" --file ${sources.risingTideLib.tests} > $out/lib.tests.md
    nixdoc --category "" --description "" --prefix "risingTideLib.types" --file ${sources.risingTideLib.types} > $out/lib.types.md
  ''
