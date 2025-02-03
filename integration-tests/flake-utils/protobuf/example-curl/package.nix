{ pkgs, lib, ... }:
pkgs.writeShellScript "example-curl" ''
  ${lib.getExe pkgs.grpcurl} -protoset ${pkgs.example-file-descriptor-set} "$@"
''
