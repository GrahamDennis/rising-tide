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
          project = rising-tide.lib.mkProject { inherit pkgs; } (
            { config, ... }:
            {
              name = "python-monorepo-root";
              subprojects = {
                package-1 = import ./projects/package-1/project.nix;
                package-2 = import ./projects/package-2/project.nix;
                package-3 = import ./projects/package-3-with-no-tests/project.nix;
              };

              tools.experimental.jetbrains = {
                enable = true;
                projectSettings = {
                  "misc.xml" = {
                    components = {
                      Black.options.sdkName = "Python 3.12 (python-monorepo)";
                      ProjectRootManager.attrs = {
                        version = "2";
                        project-jdk-name = "Python 3.12 (python-monorepo)";
                        project-jdk-type = "Python SDK";
                      };
                    };
                  };
                  "mypy.xml" = {
                    components.MypyConfigService.options = {
                      # It seems like this needs to embed the PYTHONPATH for everything to work
                      customMypyPath = builtins.toString config.tools.mypy.wrappedPackage;
                      mypyConfigFilePath = builtins.toString config.tools.mypy.configFile;
                    };
                  };
                  "modules.xml" = {
                    components = {
                      ProjectModuleManager = {
                        children = [
                          {
                            name = "modules";
                            children = [
                              {
                                name = "module";
                                attrs.fileurl = "file://$PROJECT_DIR$/.idea/python-monorepo.iml";
                                attrs.filepath = "$PROJECT_DIR$/.idea/python-monorepo.iml";
                              }
                            ];
                          }
                        ];
                      };
                    };
                  };
                };
                moduleSettings = {
                  "python-monorepo.iml" = {
                    type = "PYTHON_MODULE";
                    root = {
                      contentEntries = [
                        {
                          url = "file://$MODULE_DIR$";
                          sourceFolders = [
                            {
                              url = "file://$MODULE_DIR$/projects/package-1/src";
                              isTestSource = false;
                            }
                            {
                              url = "file://$MODULE_DIR$/projects/package-1/tests";
                              isTestSource = true;
                            }
                            {
                              url = "file://$MODULE_DIR$/projects/package-2/src";
                              isTestSource = false;
                            }
                            {
                              url = "file://$MODULE_DIR$/projects/package-2/tests";
                              isTestSource = true;
                            }
                            {
                              url = "file://$MODULE_DIR$/projects/package-3-with-no-tests/src";
                              isTestSource = false;
                            }
                          ];
                          excludeFolders = [
                            { url = "file://$MODULE_DIR$/.venv"; }
                          ];
                        }
                      ];
                      orderEntries = [
                        {
                          type = "jdk";
                          attrs = {
                            jdkType = "Python SDK";
                            jdkName = "Python 3.12 (python-monorepo)";
                          };
                        }
                        {
                          type = "sourceFolder";
                          attrs.forTests = "false";
                        }
                      ];
                    };
                    components = {
                      PyDocumentationSettings.options = {
                        format = "PLAIN";
                        myDocStringFormat = "Plain";
                      };
                      TestRunnerService.options.PROJECT_TEST_RUNNER = "py.test";
                    };
                  };
                };
              };
            }
          );
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
