{ lib, ... }:
{
  sanitizeBashIdentifier = lib.strings.sanitizeDerivationName;
}
