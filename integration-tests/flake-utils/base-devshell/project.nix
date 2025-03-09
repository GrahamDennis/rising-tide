# flake context
{ baseDevShell, ... }:
# Project context
{ ... }:
{
  name = "base-devshell-integration-test";
  mkShell = {
    enable = true;
    parentShell = baseDevShell;
  };
}
