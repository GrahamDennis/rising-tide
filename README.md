# Rising Tide

> … lifts all boats.

Rising Tide is a library for configuring [Nix] projects with sensible defaults for code-style, static analysis, linters, etc. Rising Tide currently includes tooling for Nix, C++, python and protobuf.

Inside the generated `nix develop` shell, [go-task] can be used for running linters, performing builds and running tests with:

```bash
# Run code formatters
task check

# Run the build
task build

# Run tests
task test

# List all supported tasks
task -l
```

Rising Tide also supports monorepos with subprojects. Task can be run for individual subprojects by prefixing the task with the subproject name namespaced with `:`:

```bash
# Run code formatters for subproject-1
task subproject-1:check

# Run the build for subproject-2
task subproject-2:build

# Run tests across all subprojects
task test
```

## Integrated tooling

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
  - [mypy] and [pyright] for type checking
  - [uv] for virtual environments
  - [pytest] for testing and [pytest-cov] for coverage testing
- C++-language tooling
  - [clang-tidy] for linting
  - [clang-format] for formatting
  - [cmake-format] for CMake formatting
  - [clangd] for VS Code IDE support
  - ASAN and TSAN variants of your package
- Shell scripts
  - [shellcheck] for linting
  - [shfmt] for code formatting

## Integrating with Rising Tide

Apply these tools to a project (using rising-tide's conventions) with:

<details>

<summary>C++ example</summary>

```nix
# Inside a flake-utils eachSystem block or similar
project = rising-tide.lib.mkProject { basePkgs = nixpkgs.legacyPackages.${system}; } {
  name = "my-cpp-package";
  languages.cpp = {
    enable = true;
    # This package.nix file is a normal package.nix and by default will be called like
    # `pkgs.callPackage (callPackageFunction) {}`
    callPackageFunction = import ./package.nix;
  };
};

# `project` contains the following attributes that should be included in your flake outputs:
inherit (project) devShells packages legacyPackages;
```

See the [C++ integration test](./integration-tests/flake-utils/cpp/) for a complete example.

</details>

<details>

<summary>Python (single-package) example</summary>

```nix
# Inside a flake-utils eachSystem block or similar
project = rising-tide.lib.mkProject { basePkgs = nixpkgs.legacyPackages.${system}; } {
  name = "my-python-package";
  languages.python = {
    enable = true;
    # This package.nix is a normal package.nix and by default will be called like
    # `pkgs.python3.pkgs.callPackage (callPackageFunction) {}`
    callPackageFunction = import ./package.nix;
  };
};

# `project` contains the following attributes that should be included in your flake outputs:
inherit (project) devShells packages legacyPackages;
```

See the [Python package integration test](./integration-tests/flake-utils/python-package/) for a complete example.

</details>

<details>

<summary>Python (monorepo) example</summary>

```nix
project = rising-tide.lib.mkProject { inherit pkgs; } (import ./project.nix);

# `project` contains the following attributes that should be included in your flake outputs:
inherit (project) devShells packages legacyPackages;
```

For clarity, the project configuration is recommended to be broken out into a separate project.nix file which looks like:

```nix
{
  name = "python-monorepo-root";
  subprojects = {
    package-1 = import ./projects/package-1/project.nix;
    package-2 = import ./projects/package-2/project.nix;
    package-3 = import ./projects/package-3-with-no-tests/project.nix;
  };
}
```

See the [Python monorepo integration test](./integration-tests/flake-utils/python-monorepo) for a complete example.

</details>

<details>

<summary>Protobuf API example</summary>

```nix
{
  name = "my-protobuf";
  languages.protobuf = {
    enable = true;
    grpc.enable = true;
  };
}
```

Then place all protobufs under the `proto/` directory (nested under appropriate namespaces). The above configuration will automatically produce the following Nix packages:

- `my-protobuf-file-descriptor-set`: The binary [file descriptor set][fdset] compiled from `my-protobuf`.
- `my-protobuf-cpp`: C++-language bindings.
- `my-protobuf-py`: Python-language bindings.

See the [Protobuf integration test](./integration-tests/flake-utils/proto) for an example monorepo that has two dependent protobuf modules, and consumes the generated packages above in [gRPCurl] wrappers and a python library.

</details>

[alejandra]: https://github.com/kamadorueda/alejandra
[clang-format]: https://clang.llvm.org/docs/ClangFormat.html
[clang-tidy]: https://clang.llvm.org/extra/clang-tidy/
[clangd]: https://clangd.llvm.org/
[cmake-format]: https://cmake-format.readthedocs.io/
[deadnix]: https://github.com/astro/deadnix
[fdset]: https://github.com/protocolbuffers/protobuf/blob/e390402c5e372de349af88ae0197c67529cf9360/src/google/protobuf/descriptor.proto#L54-L65
[go-task]: https://taskfile.dev/
[grpcurl]: https://github.com/fullstorydev/grpcurl
[keep-sorted]: https://github.com/google/keep-sorted
[lefthook]: https://evilmartians.github.io/lefthook/
[mdformat]: https://mdformat.readthedocs.io/
[mypy]: https://mypy.readthedocs.io/en/stable/index.html
[nil]: https://github.com/oxalica/nil
[nix]: https://nixos.org/
[nix-unit]: https://github.com/nix-community/nix-unit
[nixfmt-rfc-style]: https://github.com/NixOS/nixfmt
[pyright]: https://github.com/microsoft/pyright
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
