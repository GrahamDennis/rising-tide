# Rising Tide

> … lifts all boats.

Rising Tide is a library for configuring [Nix] projects with sensible defaults for code-style, static analysis, linters, etc.

Integrated tooling includes:

- Generic tooling
  - [go-task] for running project tasks like building, linting, running tests, etc.
  - [treefmt] for multiplexing all code formatters & linters.
  - [VS Code][vscode] project generation.
  - [lefthook] for git pre-commit hooks.
- Nix-language tooling
  - Code formatting with [nixfmt-rfc-style] or [alejandra]
  - dead-code linting with [deadnix]
  - Unit testing with [nix-unit]
  - Nix language server integration in [VS Code][vscode] using [nil]
- Python-language tooling
  - [ruff] for code formatting and linting
  - [mypy] for type checking
  - [uv] for virtual environments
  - [pytest] for testing and [pytest-cov] for coverage testing
- Shell scripts
  - [shellcheck] for linting
  - [shfmt] for code formatting

Apply these tools to a project (using rising-tide's conventions) with:

FIXME: update this documentation

```nix

project = rising-tide.lib.mkProject {
    name = "my-awesome-project";
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
};

# Then add project.allTools to nativeCheckInputs of your package or nativeBuildInputs of your devShell:

inherit (project) devShells;

```

Now inside your nix develop shell you can list all supported tasks by running `task -l`, run all checks (including code reformatting) by running `task check` or just reformatting by running `task check:treefmt`.

By default the versions of the rising-tide tooling comes from the nixos-unstable nixpkgs channel, and this can be different from the nixpkgs channel used for projects and their dependencies.

[alejandra]: https://github.com/kamadorueda/alejandra
[deadnix]: https://github.com/astro/deadnix
[go-task]: https://taskfile.dev/
[lefthook]: https://evilmartians.github.io/lefthook/
[mypy]: https://mypy.readthedocs.io/en/stable/index.html
[nil]: https://github.com/oxalica/nil
[nix]: https://nixos.org/
[nix-unit]: https://github.com/nix-community/nix-unit
[nixfmt-rfc-style]: https://github.com/NixOS/nixfmt
[pytest]: https://docs.pytest.org/en/stable/
[pytest-cov]: https://pytest-cov.readthedocs.io/en/stable/
[ruff]: https://docs.astral.sh/ruff/
[shellcheck]: https://www.shellcheck.net/
[shfmt]: https://github.com/mvdan/sh
[treefmt]: https://treefmt.com/
[uv]: https://github.com/astral-sh/uv
[vscode]: https://code.visualstudio.com/
