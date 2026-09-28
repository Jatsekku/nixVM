{ config, lib, ... }:
with lib;
with types;
let
  cfg = config;
  vmCfg = config._internalVmConfig;

  nixVmLib = import ./lib { inherit lib pkgs; };
  mkUuid = nixVmLib.misc.mkUuid;
  effectiveUuid = if cfg.uuid != null then cfg.uuid else mkUuid vmCfg.name;
in
{
  options = {
    uuid = mkOption {
      type = nullOr str;
      default = null;
      description = "UUID for the virtual machine.";
    };
  };

  config = {
    _internalVmConfig.uuid = effectiveUuid;

    _nixVirtSpec = {
      uuid = vmCfg.uuid;
    };
  };
}
