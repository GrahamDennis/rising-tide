# Rising Tide

> … lifts all boats.

Rising Tide is a library for configuring [Nix] projects with sensible defaults for code-style, static analysis, linters, etc.

Integrated tooling includes:

* Generic tooling
    * [go-task] for running project tasks like building, linting, running tests, etc.
    * [treefmt] for multiplexing all code formatters & linters.
    * [VS Code][vscode] project generation.
    * [lefthook] for git pre-commit hooks.
* Nix-language tooling
    * Code formatting with [nixfmt-rfc-style] or [alejandra]
    * dead-code linting with [deadnix]
    * Unit testing with [nix-unit]
    * Nix language server integration in [VS Code][vscode] using [nil]
* Python-language tooling
    * [ruff] for code formatting and linting
    * [mypy] for type checking
    * [uv] for virtual environments
    * [pytest] for testing and [pytest-cov] for coverage testing
* Shell scripts
    * [shellcheck] for linting
    * [shfmt] for code formatting

Apply these tools to a project (using rising-tide's conventions) with:

```nix

project = rising-tide.lib.mkProject {
    name = "my-awesome-project";
    systems = [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
};

# Then add project.tools.${system} to nativeCheckInputs of your package or nativeBuildInputs of your devShell:

devShells.default = pkgs.mkShell {
    name = "my-awesome-project";
    nativeBuildInputs = project.tools.${system}
        ++ [ /* other dev tools */ ];
};

```

By default the versions of the rising-tide tooling comes from the nixos-unstable nixpkgs channel, and this can be different from the nixpkgs channel used for projects and their dependencies.

[nix]: https://nixos.org/
[go-task]: https://taskfile.dev/
[nixfmt-rfc-style]: https://github.com/NixOS/nixfmt
[alejandra]: https://github.com/kamadorueda/alejandra
[deadnix]: https://github.com/astro/deadnix
[nix-unit]: https://github.com/nix-community/nix-unit
[treefmt]: https://treefmt.com/
[vscode]: https://code.visualstudio.com/
[nil]: https://github.com/oxalica/nil
[lefthook]: https://evilmartians.github.io/lefthook/
[ruff]: https://docs.astral.sh/ruff/
[mypy]: https://mypy.readthedocs.io/en/stable/index.html
[uv]: https://github.com/astral-sh/uv
[pytest]: https://docs.pytest.org/en/stable/
[pytest-cov]: https://pytest-cov.readthedocs.io/en/stable/
[shellcheck]: https://www.shellcheck.net/
[shfmt]: https://github.com/mvdan/sh