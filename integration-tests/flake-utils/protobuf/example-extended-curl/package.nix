{ pkgs, lib, ... }:
pkgs.writeShellScript "example-extended-curl" ''
  ${lib.getExe pkgs.grpcurl} -protoset ${pkgs.example-extended-file-descriptor-set} "$@"
''
