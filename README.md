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

Additionally, a [VS Code][vscode] project will be generated at `.vscode/settings.json` that is ready-to-use with language server tooling integrated.

## Integrated tooling

Integrated tooling includes:

- Generic tooling
  - [go-task] for running project tasks like building, linting, running tests, etc.
  - [treefmt] for multiplexing all code formatters & linters.
  - [VS Code][vscode] project generation, including multi-root projects for monorepos.
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
  - [ASAN] and [TSAN] variants of your package
- Shell scripts
  - [shellcheck] for linting
  - [shfmt] for code formatting

## Using Rising Tide

### VS Code

Rising Tide will automatically generate `.vscode` directories with VS Code project settings and recommended extensions. Additionally for monorepos (aka Rising Tide projects that use the `subprojects` attribute) a VS Code [multi-root workspace][vscode-multi-root-workspace] is generated in `.vscode/${rootProjectName}.code-workspace`. Multi-root workspaces are necessary for correct Pytest integration in monorepos for example.

The VS Code generated projects support:

- General:
  - Use [direnv] to automatically inherit the `nix develop` environment
- Nix:
  - Nix Language server using [nil]
- Python:
  - [pytest] integration including with the Python debugger. For python monorepos this requires using the generated multi-root workspace in `.vscode/${rootProjectName}.code-workspace`.
  - [mypy] and [ruff] language server integration for type linting and code formatting respectively
- C++:
  - [gtest] test discovery and execution including using the debugger.

### JetBrains IDEs

For Python projects a PyCharm `.idea` project is generated and preconfigured.

For C++ projects, a CLion `.idea` project is generated, however some additional steps are required for CLion to become aware of the full `nix develop` environment:

1. Create a new Toolchain in CLion where the environment file is `.idea/scripts/env.sh` (inside your project), and the path to CMake is `.idea/scripts/cmake`.
1. Select this Toolchain for your project.

## Integrating Rising Tide

A minimal `flake.nix` using Rising Tide:

<details>

<summary><a name="minimal-flake-nix"></a>flake.nix</summary>

```nix
{
  description = "Example flake using Rising Tide";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
    rising-tide.url = "github:GrahamDennis/rising-tide";
  };

  outputs =
    inputs@{
      flake-utils,
      nixpkgs,
      rising-tide,
      ...
    }:
    let
      perSystemOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          project = rising-tide.lib.mkProject { basePkgs = nixpkgs.legacyPackages.${system}; } (import ./project.nix);
        in
        rec {
          inherit project;
          inherit (project) packages devShells hydraJobs legacyPackages;
        }
      );
      # mkSystemIndependentOutput produces the `overlays` and `pythonOverlays` attributes combining the system-specific
      # attributes above
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };
    in
    perSystemOutputs
    // systemIndependentOutputs;
}
```

</details>

`project.nix` contains the configuration of a Rising Tide project:

<details>

<summary>C++ <code>project.nix</code> example</summary>

```nix
{
  name = "my-cpp-package";
  languages.cpp = {
    enable = true;
    # This package.nix file is a normal package.nix and by default will be called like
    # `pkgs.callPackage (callPackageFunction) {}`
    callPackageFunction = import ./package.nix;
  };
};
```

See the [C++ integration test](./integration-tests/flake-utils/cpp/) for a complete example.

</details>

<details>

<summary>Python (single-package) <code>project.nix</code> example</summary>

```nix
{
  name = "my-python-package";
  languages.python = {
    enable = true;
    # This package.nix is a normal package.nix and by default will be called like
    # `pkgs.python3.pkgs.callPackage (callPackageFunction) {}`
    callPackageFunction = import ./package.nix;
  };
};
```

See the [Python package integration test](./integration-tests/flake-utils/python-package/) for a complete example.

</details>

<details>

<summary>Python (monorepo) <code>project.nix</code> example</summary>

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

<summary>Protobuf API <code>project.nix</code> example</summary>

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

## Design overview

### Projects

The central concept in Rising Tide is that of a _project_. A project corresponds to either a single Nix package (and associated `nix develop` shell) or is the parent of a set of child `subprojects` for example in a monorepo. Subprojects may be nested arbitrarily.

### Tooling

Each project has associated _tooling_ which can be enabled and configured via the `tools.*` project options. Tooling includes linters, code formatters, VS Code settings, language servers, etc. Tooling can be enabled and configured separately, and while rising-tide includes default configurations of some tools via rising-tide _conventions_ (see below), those can be disabled or overridden.

Tooling-related options and configuration are defined under [./modules/projects/tools/][tooling].

### Languages

Language-specific build settings are enabled and configured via the `languages.*` project options. For example:

- For python, the python package set to build on top of is defined by `languages.python.pythonPackages`,
- For C++, [ASAN] and [TSAN] can be enabled and configured by `languages.cpp.sanitizers.{asan,tsan}.*`. These features require configuring the base C++ package via `languages.cpp.callPackageFunction`.
- For protobuf the source directory can be configured via `languages.protobuf.src`, gRPC enabled with `languages.protobuf.grpc.enable` and imported protobuf packages referenced via `languages.protobuf.importPaths`.

Language-related options and configuration are defined under [./modules/projects/languages/][languages].

### Conventions

_Conventions_ (`conventions.*`) provide default configurations for tooling (e.g. code styles, linter settings) and defaults for which tooling should be enabled depending on which language has been configured for a project. Rising Tide provides its own conventions which are configured under `conventions.risingTide.*`. These conventions are default-enabled if a project is created via `risingTide.lib.mkProject`, however conventions can have their configurations overridden, or disabled. Additionally the default-enable of Rising Tide conventions can be avoided by using `risingTide.lib.mkBaseProject` in place of `risingTide.lib.mkProject` for creating projects. Additional conventions can be created and distributed separately from Rising Tide itself and applied via the `projectModules` argument to `mkProject` / `mkBaseProject`.

Conventions are defined under [./modules/projects/conventions/][conventions].

### Project configurations are Nix modules

Rising Tide uses the [Nix module system][module-system] for project configuration. This is the same system used for configuring NixOS computers. Using the module system allows project configuration to be merged / overridden using the standard `lib.mkForce` / `lib.mkOverride` / `lib.mkBefore` / `lib.mkAfter` utilities commonly used in NixOS computer configuration. Additionally, this enables additional modules to be defined outside of Rising Tide and used to extend the project configuration options that it provides.

For example, mypy can be configured to disallow expressions to have the type `Any` with:

```nix
# project.nix
{lib, ...}:
{
  # Note: this will be merged with any other mypy configuration set via `tools.mypy.config`
  tools.mypy.config.disallow_any_expr = true;
}
```

In a monorepo, this would only apply to a single project and not any nested subprojects or other projects in the repo. To apply this configuration to all projects and its subprojects, one could write:

```nix
customProjectModule = {
  tools.mypy.config.disallow_any_expr = true;
};
project = rising-tide.lib.mkProject {
  basePkgs = nixpkgs.legacyPackages.${system};
  # customProjectModule will apply to the root project and all nested subprojects
  projectModules = [ customProjectModule ];
} (import ./project.nix);
```

This module can also be packaged up as a Nix module published from a flake and consumed by other Nix repositories. In this situation, the conventions packaged as the module should be able to be enabled/configured via `conventions.<my-convention>.*`. For example:

```nix
customConventionModule = {config, ...}: {
  # This is just a Nix module
  options = {
    # Optionally this could be default-enabled if desired.
    conventions.myConvention.enable = lib.mkEnableOption "Enable my custom convention";
  };
  config = lib.mkIf config.conventions.myConvention.enable {
    tools.mypy.config.disallow_any_expr = true;
  };
};
# This module can then be consumed inside this package or downstream via:
project = rising-tide.lib.mkProject { # or lib.mkBaseProject to not default-enable rising-tide conventions
  basePkgs = nixpkgs.legacyPackages.${system};
  projectModules = [
    customConventionModule
    {
      # If the convention isn't default-enabled
      conventions.myConvention.enable = true;
    }
  ];
};
```

### Evaluated project outputs

The `project` variable above is expected to be evaluated inside a per-system context, e.g. `flake-utils.lib.eachSystem`. The generated project produces several attributes that should be included (or merged with) a flake's outputs. These include:

- `packages`: A flat attribute set of the packages produced by Rising Tide.

- `devShells`: A flat attribute set of the devShells configured by Rising Tide. These devShells match the corresponding packages and have all enabled tooling included.

- `legacyPackages`: Rising Tide produces a package overlay and applies this on top of the `basePkgs` passed to `mkProject` (unless that has already been done and passed as the `pkgs` argument instead). `legacyPackages` is the upstream `basePkgs` with this overlay applied. Packages under `packages.*` are extracted from `legacyPackages`.

- `hydraJobs`: Hydra Jobs for evaluating the `packages` produced by Rising Tide using [nix-eval-jobs], [nix-fast-build] or similar.

- `overlay`: A system-specific overlay that was applied on top of `basePkgs` to produce `legacyPackages` (or can be used to create the `pkgs` argument to `mkProject`). Similarly a system-specific python overlay is available at `languages.pythonOverlay`.

  While `overlay` and `pythonOverlay` are system-specific, an `overlays` attribute (and `pythonOverlays` attribute) can be constructed that supports all systems supported by your flake using `risingTide.lib.project.mkSystemIndependentOutputs`. See the [minimal flake.nix example above](#minimal-flake-nix).

### Trying Rising Tide

Rising Tide contains several [integration tests](./integration-tests/flake-utils/) that also serve as working examples of Rising Tide functionality. Play with these by:

1. Clone Rising Tide
1. `cd` into the integration test of your choice
1. Run `nix develop` / `nix repl .`.

[alejandra]: https://github.com/kamadorueda/alejandra
[asan]: https://github.com/google/sanitizers/wiki/addresssanitizer
[clang-format]: https://clang.llvm.org/docs/ClangFormat.html
[clang-tidy]: https://clang.llvm.org/extra/clang-tidy/
[clangd]: https://clangd.llvm.org/
[cmake-format]: https://cmake-format.readthedocs.io/
[conventions]: ./modules/projects/conventions/
[deadnix]: https://github.com/astro/deadnix
[direnv]: https://direnv.net/
[fdset]: https://github.com/protocolbuffers/protobuf/blob/e390402c5e372de349af88ae0197c67529cf9360/src/google/protobuf/descriptor.proto#L54-L65
[go-task]: https://taskfile.dev/
[grpcurl]: https://github.com/fullstorydev/grpcurl
[gtest]: https://github.com/google/googletest
[keep-sorted]: https://github.com/google/keep-sorted
[languages]: ./modules/projects/languages/
[lefthook]: https://evilmartians.github.io/lefthook/
[mdformat]: https://mdformat.readthedocs.io/
[module-system]: https://nix.dev/tutorials/module-system/
[mypy]: https://mypy.readthedocs.io/en/stable/index.html
[nil]: https://github.com/oxalica/nil
[nix]: https://nixos.org/
[nix-eval-jobs]: https://github.com/nix-community/nix-eval-jobs
[nix-fast-build]: https://github.com/Mic92/nix-fast-build
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
[tooling]: ./modules/projects/tools/
[treefmt]: https://treefmt.com/
[tsan]: https://github.com/google/sanitizers/wiki/ThreadSanitizerCppManual
[uv]: https://github.com/astral-sh/uv
[vscode]: https://code.visualstudio.com/
[vscode-multi-root-workspace]: https://code.visualstudio.com/docs/editor/workspaces/multi-root-workspaces
