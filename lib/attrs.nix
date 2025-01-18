# rising-tide flake context
{ lib, ... }:
rec {
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

  flattenAttrsRecursiveCond =
    pred:
    let
      toAttrName = builtins.concatStringsSep ".";
      recurse =
        prefix: set:
        builtins.concatMap (
          name:
          let
            v = set.${name};
            path = prefix ++ [ name ];
          in
          if builtins.isAttrs v && pred v then
            recurse path v
          else
            [
              (lib.nameValuePair (toAttrName path) v)
            ]
        ) (builtins.attrNames set);
    in
    set: builtins.listToAttrs (recurse [ ] set);

  flattenAttrsRecursive = flattenAttrsRecursiveCond (_as: true);
}
