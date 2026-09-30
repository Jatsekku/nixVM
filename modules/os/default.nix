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

  OSes = {
    windows = import ./windows.nix { inherit lib pkgs; };
    linux = import ./linux.nix { inherit lib; };
  };
in
{
  options = {
    os =
      let
        allowedOSes = attrNames OSes;
        allowedOSesStr = concatStringsSep ", " allowedUnits;
      in
      mkOption {
        type = enum allowedOSes;
        description = "Target guest operating system. Allowed values: ${allowedOSesStr}";
      };
  };

  config = {
    _internalVmConfig.os = cfg.os;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

        mkOS: osName: OSes.${osName}._nixVirtSpec;
      in
      mkOS vmCfg.os;
  };
}
