{
  config,
  hostConfig,
  lib,
  name,
  pkgs,
  ...
}:
with builtins;
with lib;
with types;
let
in
{
  imports = import ./module-list.nix;

  options = {
    mode = mkOption {
      type = enum [
        "none"
        "stealth"
      ];
      default = "none";
    };

    extraNixVirtConfig = mkOption {
      type = attrs;
      default = { };
      description = "Extra config for VM";
    };

    _internalVmConfig = mkOption {
      type = attrs;
      default = { };
      internal = true;
      description = "Internal source of truth for VM definition";
    };

    _nixVirtSpec = mkOption {
      type = types.mkOptionType {
        name = "recursiveAttrsWithListConcat";
        description = "Attribute set with recursive merging and list concatenation";
        check = isAttrs;
        merge =
          loc: defs:
          let
            mergeTwo =
              acc: val:
              if isAttrs acc && isAttrs val then
                lib.zipAttrsWith (name: values: foldl' mergeTwo (head values) (tail values)) [
                  acc
                  val
                ]
              else if isList acc && isList val then
                acc ++ val
              else
                val;
          in
          foldl' mergeTwo { } (map (d: d.value) defs);
      };
      default = { };
      internal = true;
      description = "VM definition for NixVirt";
    };
  };

  config = {
    _internalVmConfig = {
      name = name;
      extraNixVirtConfig = config.extraNixVirtConfig;
    };

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;
      in
      recursiveUpdate {
        name = vmCfg.name;

        clock = {
          offset = "utc";
          timer = [
            {
              name = "rtc";
              tickpolicy = "catchup";
            }
            {
              name = "pit";
              tickpolicy = "delay";
            }
            {
              name = "hpet";
              present = false;
            }
          ];
        };

        features = {
          acpi = { };
          apic = { };
        };

        os = {
          boot = [
            { dev = "hd"; }
            { dev = "cdrom"; }
          ];
        };
      } vmCfg.extraNixVirtConfig;
  };
}
