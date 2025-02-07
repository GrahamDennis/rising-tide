# python packages context
{
  stdenv,
  pkgs,
  lib,
}:
let
  asanHook = pkgs.makeSetupHook {
    name = "asan-hook";
  } ./hooks/asan.sh;
  enableAsan =
    drv:
    lib.overrideDerivation drv (prev: {
      nativeBuildInputs = (prev.nativeBuildInputs or [ ]) ++ [ asanHook ];
    });
  originalDrv = stdenv.mkDerivation {
    name = "cpp-package";
    src = ./.;
    hardeningDisable = [ "all" ];

    nativeBuildInputs = with pkgs; [
      cmake
      ninja
    ];
    buildInputs = with pkgs; [ fmt ];

    doCheck = true;
    checkInputs = with pkgs; [ gtest ];
  };
  wrappedDrv = originalDrv.overrideAttrs (prev: {
    passthru = (prev.passthru or { }) // {
      withAsan = enableAsan originalDrv;
    };
  });
in
wrappedDrv
