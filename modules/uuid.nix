{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib;
with types;
let
  cfg = config;

  nixVmLib = import ./lib { inherit lib pkgs; };
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
    _internalVmConfig.uuid = cfg.uuid;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

        inherit (nixVmLib.misc) mkUuid;

        uuid = if vmCfg.uuid != null then vmCfg.uuid else (mkUuid vmCfg.name);
      in
      {
        inherit uuid;
      };
  };
}
