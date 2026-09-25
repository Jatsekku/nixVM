{ config, lib, ... }:
with lib;
with types;
let
  cfg = config.hardware.disks;

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
    _internalVmConfig.disks = cfg;
  };
}
