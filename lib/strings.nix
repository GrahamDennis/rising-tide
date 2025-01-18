# rising-tide flake context
{ lib, ... }:
{
  sanitizeBashIdentifier = lib.strings.sanitizeDerivationName;
}
