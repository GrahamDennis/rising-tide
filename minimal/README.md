# A minimal flake interface for Rising Tide

This is an experimental minimal flake interface for Rising Tide, that attempts to provide a solution for ever-growing flake.lock files. Instead of consuming Rising-Tide normally with an input like:

```nix
inputs.rising-tide.url = "github:GrahamDennis/rising-tide";
```

Instead use:

```nix
inputs.rising-tide.url = "github:GrahamDennis/rising-tide?dir=minimal";
```

This is a drop-in replacement, however your flake.lock will only reference rising-tide itself, and not any of its transitive dependencies. The cost of using the minimal flake interface is that downstream flake consumers are not able to override any of the inputs of Rising Tide itself.

## How does this work?

This subflake simply calls `builtins.getFlake` on the parent flake using the same nix source package as the minimal subflake.
