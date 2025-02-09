# rising-tide flake context
{
  lib,
  risingTideLib,
  ...
}:
let
  inherit (lib) types;
in
# project context
{
  config,
  system,
  ...
}:
let
  cfg = config.tools.experimental.jetbrains;
  settingsFormat = risingTideLib.perSystem.${system}.formats.xml { };
  componentType = types.submodule (
    { config, name, ... }:
    {
      options = {
        options = lib.mkOption {
          type = types.attrsOf types.str;
          default = { };
        };
        attrs = lib.mkOption {
          type = types.attrsOf types.str;
          default = { };
        };
        children = lib.mkOption {
          type = types.listOf settingsFormat.type;
          default = [ ];
        };
        xml = mkXmlOption {
          name = "component";
          attrs = {
            inherit name;
          } // config.attrs;
          children =
            (lib.mapAttrsToList (name: value: {
              name = "option";
              attrs = { inherit name value; };
            }) config.options)
            ++ config.children;
        };
      };
    }
  );
  projectSettingsType = types.submodule (
    { config, ... }:
    {
      options = {
        components = lib.mkOption {
          type = types.attrsOf componentType;
          default = { };
        };
        xml = mkXmlOption {
          name = "project";
          attrs.version = "4";
          children = builtins.map (component: component.xml) (builtins.attrValues config.components);
        };
      };
    }
  );
  urlOption = lib.mkOption { type = types.str; };
  typeOption = lib.mkOption { type = types.str; };
  mkXmlOption =
    value:
    lib.mkOption {
      readOnly = true;
      description = "The generated XML for this element";
      visible = "shallow";
      type = settingsFormat.type;
      default = value;
      defaultText = lib.literalMD "The generated XML for this element";
    };
  toXml = submodule: submodule.xml;
  sourceFolderType = types.submodule (
    { config, ... }:
    {
      options = {
        url = urlOption;
        isTestSource = lib.mkOption { type = types.bool; };
        xml = mkXmlOption {
          name = "sourceFolder";
          attrs = {
            inherit (config) url;
            isTestSource = lib.boolToString config.isTestSource;
          };
        };
      };
    }
  );
  excludeFolderType = types.submodule (
    { config, ... }:
    {
      options = {
        url = urlOption;
        xml = mkXmlOption {
          name = "excludeFolder";
          attrs = { inherit (config) url; };
        };
      };
    }
  );
  contentEntryType = types.submodule (
    { config, ... }:
    {
      options = {
        url = urlOption;
        sourceFolders = lib.mkOption {
          type = types.listOf sourceFolderType;
          default = [ ];
        };
        excludeFolders = lib.mkOption {
          type = types.listOf excludeFolderType;
          default = [ ];
        };
        xml = mkXmlOption {
          name = "content";
          attrs.url = config.url;
          children = (builtins.map toXml config.sourceFolders) ++ (builtins.map toXml config.excludeFolders);
        };
      };
    }
  );
  orderEntryType = types.submodule (
    { config, ... }:
    {
      options = {
        type = typeOption;
        attrs = lib.mkOption {
          type = types.attrsOf types.str;
          default = { };
        };
        xml = mkXmlOption {
          name = "orderEntry";
          attrs = {
            type = config.type;
          } // config.attrs;
        };
      };
    }
  );
  moduleRootType = types.submodule (
    { config, ... }:
    {
      options = {
        contentEntries = lib.mkOption {
          type = types.listOf contentEntryType;
          default = [ ];
        };
        orderEntries = lib.mkOption {
          type = types.listOf orderEntryType;
          default = [ ];
        };
        xml = mkXmlOption {
          name = "component";
          attrs.name = "NewModuleRootManager";
          children = (builtins.map toXml config.contentEntries) ++ (builtins.map toXml config.orderEntries);
        };
      };
    }
  );
  moduleSettingsType = types.submodule (
    { config, ... }:
    {
      options = {
        type = typeOption;
        components = lib.mkOption {
          type = types.attrsOf componentType;
          default = { };
        };
        root = lib.mkOption {
          type = types.nullOr moduleRootType;
          default = null;
        };
        xml = mkXmlOption {
          name = "module";
          attrs.type = config.type;
          attrs.version = "4";
          children =
            (lib.optional (config.root != null) config.root.xml)
            ++ (builtins.map (component: component.xml) (builtins.attrValues config.components));
        };
      };
    }
  );
in
{
  options = {
    tools.experimental.jetbrains = {
      enable = lib.mkEnableOption "Enable JetBrains IDE integration";
      projectSettings = lib.mkOption {
        type = types.attrsOf projectSettingsType;
        default = { };
      };
      moduleSettings = lib.mkOption {
        type = types.attrsOf moduleSettingsType;
        default = { };
      };
      requiredPlugins = lib.mkOption {
        type = types.attrsOf types.bool;
        default = { };
      };
      xml = lib.mkOption {
        type = types.attrsOf settingsFormat.type;
        default = { };
      };
      xmlFiles = lib.mkOption {
        readOnly = true;
        type = types.attrsOf types.pathInStore;
        default = builtins.mapAttrs (name: xml: settingsFormat.generate name xml) cfg.xml;
      };
    };
  };
  config = lib.mkIf cfg.enable {
    tools.experimental.jetbrains = {
      projectSettings."externalDependencies.xml" = lib.mkIf (cfg.requiredPlugins != { }) {
        components.ExternalDependencies.children = lib.mapAttrsToList (
          pluginId: enable:
          (lib.mkIf enable {
            name = "plugin";
            attrs.id = pluginId;
          })
        ) cfg.requiredPlugins;
      };
      xml = lib.mkMerge [
        (builtins.mapAttrs (_name: projectSettings: projectSettings.xml) cfg.projectSettings)
        (builtins.mapAttrs (_name: moduleSettings: moduleSettings.xml) cfg.moduleSettings)
      ];
    };
    tools.nixago.requests = lib.mapAttrsToList (name: file: {
      data = file;
      output = ".idea/${name}";
      hook.mode = "copy";
    }) cfg.xmlFiles;
  };
}
