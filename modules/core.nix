{
  config,
  lib,
  pkgs,
  hostConfig,
  name,
  ...
}:
with lib;
with types;
let
  vmCfg = config._internalVmConfig;
in
{
  imports = import ./module-list.nix;

  options = {
    _internalVmConfig = mkOption {
      type = attrs;
      default = { };
      internal = true;
      description = "Internal source of truth for VM definition";
    };

    _nixVirtSpec = mkOption {
      type = types.mkOptionType {
        name = "recursiveAttrs";
        description = "Attribute set with recursive merging";
        check = isAttrs;
        merge = loc: defs: foldl' recursiveUpdate { } (map (d: d.value) defs);
      };
      default = { };
      internal = true;
      description = "VM definition for NixVirt";
    };
  };

  config = {
    _internalVmConfig.name = name;

    _nixVirtSpec = {
      name = vmCfg.name;

      os = {
        boot = [
          { dev = "hd"; }
          { dev = "cdrom"; }
        ];
      };
    };
  };
}
