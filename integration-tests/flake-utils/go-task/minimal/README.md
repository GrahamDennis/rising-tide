# A minimal flake interface for go-task-integration-test

This is an experimental minimal flake interface that attempts to provide a solution for ever-growing flake.lock files. Instead of consuming this flake normally with an input like:

```nix
inputs.go-task-integration-test.url = "insert-url-here";
```

Instead use:

```nix
inputs.go-task-integration-test.url = "insert-url-here?dir=minimal";
```

This is a drop-in replacement, however your flake.lock will only reference this flake,
and not any of its transitive dependencies. The cost of using the minimal flake interface
is that downstream flake consumers are not able to override any of the inputs of this flake.

## How does this work?

This subflake simply calls `builtins.getFlake` on the parent flake using the same nix source package
as the minimal subflake.
