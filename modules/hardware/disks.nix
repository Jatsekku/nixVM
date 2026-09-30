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
  cfg = config.hardware;

  nixVmLib = import ./../lib { inherit lib pkgs; };
  inherit (nixVmLib.disks) mkDisks;

  diskType = submodule {
    options = {
      path = mkOption {
        type = str;
        description = "Path to the disk image or block device.";
      };
      serial = mkOption {
        type = str;
        default = "";
        description = "Optional serial number for the disk.";
      };
      bus = mkOption {
        type = nullOr (enum [
          "ide"
          "nvme"
          "sata"
          "scsi"
          "sd"
          "usb"
          "virtio"
          "xen"
        ]);
        default = null;
        description = "Controller bus type for the disk.";
      };

      # Disk creation
      create = mkOption {
        type = bool;
        default = false;
        description = "Whether NixOS should automatically create the disk image if it does not exist.";
      };
      size = mkOption {
        type = nullOr str;
        default = null;
        description = "Size of the disk to create (e.g. '20G', '500M')";
      };
    };
  };
in
{
  options = {
    hardware.disks = mkOption {
      type = listOf diskType;
      default = [ ];
      description = "List disks allocated to the VM";
    };
  };

  config = {
    _internalVmConfig.disks = cfg.disks;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;
      in
      {
        devices = {
          disk = mkDisks vmCfg.disks;
        };
      };
  };
}
