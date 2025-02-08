{
  description = "python-monorepo";

  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-24.11";
  };

  outputs =
    inputs@{
      flake-utils,
      nixpkgs,
      self,
      ...
    }:
    let
      rising-tide = builtins.getFlake (
        builtins.unsafeDiscardStringContext "path:${self.sourceInfo}?narHash=${self.narHash}"
      );
      perSystemOutputs = flake-utils.lib.eachDefaultSystem (
        system:
        let
          # FIXME: Make this really easy to do somehow. Perhaps by letting folks pass a nixpkgs without
          # the overlay applied to the project
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ self.overlays.default ];
          };
          project = rising-tide.lib.mkProject { inherit pkgs; } {
            name = "python-monorepo-root";
            subprojects = {
              package-1 = import ./projects/package-1/project.nix;
              package-2 = import ./projects/package-2/project.nix;
              package-3 = import ./projects/package-3-with-no-tests/project.nix;
            };

            tools.jetbrains = {
              enable = true;
              xml = {
                "python-monorepo.iml.fake" = {
                  name = "module";
                  attrs.type = "PYTHON_MODULE";
                  attrs.version = "4";
                  children = [
                    {
                      name = "component";
                      attrs.name = "NewModuleRootManager";
                      children = [
                        {
                          name = "content";
                          attrs.url = "file://$MODULE_DIR$";
                          children = [
                            {
                              name = "sourceFolder";
                              attrs.url = "file://$MODULE_DIR$/projects/package-1/src";
                              attrs.isTestSource = "false";
                            }
                            {
                              name = "sourceFolder";
                              attrs.url = "file://$MODULE_DIR$/projects/package-1/tests";
                              attrs.isTestSource = "true";
                            }
                            {
                              name = "sourceFolder";
                              attrs.url = "file://$MODULE_DIR$/projects/package-2/src";
                              attrs.isTestSource = "false";
                            }
                            {
                              name = "sourceFolder";
                              attrs.url = "file://$MODULE_DIR$/projects/package-2/tests";
                              attrs.isTestSource = "true";
                            }
                            {
                              name = "sourceFolder";
                              attrs.url = "file://$MODULE_DIR$/projects/package-3-with-no-tests/src";
                              attrs.isTestSource = "false";
                            }
                            {
                              name = "excludeFolder";
                              attrs.url = "file://$MODULE_DIR$/.venv";
                            }
                          ];
                        }
                        {
                          name = "orderEntry";
                          attrs.type = "jdk";
                          attrs.jdkName = "Python 3.12 (python-monorepo)";
                          attrs.jdkType = "Python SDK";
                        }
                        {
                          name = "orderEntry";
                          attrs.type = "sourceFolder";
                          attrs.forTests = "false";
                        }
                      ];
                    }
                    {
                      name = "component";
                      attrs.name = "PyDocumentationSettings";
                      children = [
                        {
                          name = "option";
                          attrs.name = "format";
                          attrs.value = "PLAIN";
                        }
                        {
                          name = "option";
                          attrs.name = "myDocStringFormat";
                          attrs.value = "Plain";
                        }
                      ];
                    }
                    {
                      name = "component";
                      attrs.name = "TestRunnerService";
                      children = [
                        {
                          name = "option";
                          attrs.name = "PROJECT_TEST_RUNNER";
                          attrs.value = "py.test";
                        }
                      ];
                    }
                  ];
                };
              };
            };
          };
        in
        rec {
          inherit project;
          inherit (project) packages devShells;
        }
      );
      systemIndependentOutputs = rising-tide.lib.project.mkSystemIndependentOutputs {
        rootProjectBySystem = perSystemOutputs.project;
      };
    in
    perSystemOutputs
    // {
      /*
        When using rising-tide externally you should just write something like `perSystemOutputs // systemIndependentOutputs`,
        however due to the way we import rising-tide locally in integration-tests, to avoid infinite recursion,
        it must be clear to the nix evaluator that systemIndependentOutputs doesn't set the `sourceInfo` or `narHash`
        keys.
      */
      inherit (systemIndependentOutputs) overlays pythonOverlays;
      inputs = inputs // {
        inherit rising-tide;
      };
    };
}
