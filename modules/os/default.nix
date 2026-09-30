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
        allowedOSesStr = concatStringsSep ", " allowedOSes;
      in
      mkOption {
        type = nullOr (enum allowedOSes);
        default = null;
        description = "Target guest operating system. Allowed values: ${allowedOSesStr}";
      };
  };

  config = {
    _internalVmConfig.os =
      let
        assertOS =
          os: if os == null then throw "You must specify an operating system for the VM: ${name}" else os;
      in
      assertOS cfg.os;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

        # TODO: temporary
        settings = {
          nvramPath = "/var/lib/libvirt/qemu/nvram/${name}_VARS.fd";
        };
        mkOS = osName: OSes.${osName}.mkOS settings;
      in
      mkOS vmCfg.os;
  };
}
