{ lib, ... }:
{
  filterAttrsByPathRecursive =
    pred:
    let
      recurse =
        prefix: set:
        builtins.listToAttrs (
          builtins.concatMap (
            name:
            let
              v = set.${name};
            in
            if pred (prefix ++ [ name ]) v then
              [
                (lib.nameValuePair name (if builtins.isAttrs v then recurse (prefix ++ [ name ]) v else v))
              ]
            else
              [ ]
          ) (builtins.attrNames set)
        );
    in
    recurse [ ];
}
