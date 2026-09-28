{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}:
with lib;
with types;
let
  cfg = config.hardware.cpu;

  allowedArchs = [
    "x86_64"
    "aarch64"
  ];
  allowedArchsStr = concatStringsSep ", " allowedArchs;
in
{
  options = {
    hardware.cpu = {
      arch = mkOption {
        type = enum allowedArchs;
        default = "x86_64";
        description = "CPU architecture for the VM. Allowed values: ${allowedArchsStr}";
      };
      cores = mkOption {
        type = ints.positive;
        default = 2;
        description = "Number of vCPU cores allocated to the VM";
      };
      machine = mkOption {
        type = nullOr str;
        default = null;
        description = "Machine type for the VM (e.g., 'q35', 'pc')";
      };
    };
  };

  config = {
    _internalVmConfig.cpu = {
      cores = cfg.cores;
      arch = cfg.arch;
      machine = cfg.machine;
    };

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

        nixVmLib = import ./../lib { inherit lib pkgs; };
        inherit (nixVmLib.misc)
          getHostArch
          getHostOS
          getHypervisorType
          getMachineType
          ;

        hostSystem = pkgs.stdenv.hostPlatform.system;
        hostArch = getHostArch hostSystem;
        hostOS = getHostOS hostSystem;
        hypervisorType = getHypervisorType hostOS hostArch vmCfg.cpu.arch;
        machineType = getMachineType vmCfg.cpu.machine vmCfg.cpu.arch;
      in
      {
        type = hypervisorType;

        cpu = {
          # Mimic host's physical CPU
          mode = "host-passthrough";
          # Drop VM live-migration but increase performance
          migratable = false;
        };

        vcpu = {
          count = vmCfg.cpu.cores;
          placement = "static";
        };

        os.arch = vmCfg.cpu.arch;
        os.type = "hvm";
        os.machine = machineType;

        devices = {
          emulator = "${pkgs.qemu}/bin/qemu-system-${vmCfg.cpu.arch}";
        };
      };
  };
}
