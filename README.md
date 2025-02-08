# Rising Tide

> … lifts all boats.

Rising Tide is a library for configuring [Nix] projects with sensible defaults for code-style, static analysis, linters, etc.

Integrated tooling includes:

- Generic tooling
  - [go-task] for running project tasks like building, linting, running tests, etc.
  - [treefmt] for multiplexing all code formatters & linters.
  - [VS Code][vscode] project generation.
  - [lefthook] for git pre-commit hooks.
  - [keep-sorted] for language-agnostic sorting of lines / code blocks
  - [mdformat] for formatting Markdown
  - [ripsecrets] for secret scanning
  - [taplo] for TOML file formatting
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
- C++-language tooling
  - [clang-tidy] for linting
  - [clang-format] for formatting
  - [cmake-format] for CMake formatting
  - [clangd] for VS Code IDE support
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
[clang-format]: https://clang.llvm.org/docs/ClangFormat.html
[clang-tidy]: https://clang.llvm.org/extra/clang-tidy/
[clangd]: https://clangd.llvm.org/
[cmake-format]: https://cmake-format.readthedocs.io/
[deadnix]: https://github.com/astro/deadnix
[go-task]: https://taskfile.dev/
[keep-sorted]: https://github.com/google/keep-sorted
[lefthook]: https://evilmartians.github.io/lefthook/
[mdformat]: https://mdformat.readthedocs.io/
[mypy]: https://mypy.readthedocs.io/en/stable/index.html
[nil]: https://github.com/oxalica/nil
[nix]: https://nixos.org/
[nix-unit]: https://github.com/nix-community/nix-unit
[nixfmt-rfc-style]: https://github.com/NixOS/nixfmt
[pytest]: https://docs.pytest.org/en/stable/
[pytest-cov]: https://pytest-cov.readthedocs.io/en/stable/
[ripsecrets]: https://github.com/sirwart/ripsecrets
[ruff]: https://docs.astral.sh/ruff/
[shellcheck]: https://www.shellcheck.net/
[shfmt]: https://github.com/mvdan/sh
[taplo]: https://taplo.tamasfe.dev/
[treefmt]: https://treefmt.com/
[uv]: https://github.com/astral-sh/uv
[vscode]: https://code.visualstudio.com/
