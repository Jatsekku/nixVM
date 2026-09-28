{ config, lib, ... }:
with lib;
with types;
let
  cfg = config;
  vmCfg = config._internalVmConfig;

  nixVmLib = import ./../lib { inherit lib; };

  allowedOSes = [
    "linux"
    "windows"
  ];
  allowedOSesStr = concatStringsSep ", " allowedUnits;
in
{
  options = {
    os = mkOption {
      type = enum allowedOSes;
      description = "Target guest operating system. Allowed values: ${allowedOSesStr}";
    };
  };

  config = {
    _internalVmConfig.os = cfg.os;

    _nixVirtSpec = {

    };
  };
}
