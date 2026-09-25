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
  inherit (nixVmLib.misc) getHostArch;

  hostSystem = pkgs.stdenv.hostPlatform.system;
  hostArch = getHostArch hostSystem;

  /*nixfmt:disable*/
  # 'f' stands for facter
  freport = hostConfig.nix-vm.facter.report or { };
    fhardware = freport.hardware or { };
      fcpu = fhardware.cpu or [ ];
        fcpu0 = if fcpu != [ ] then head fcpu else { };
          fvendor = fcpu0.vendor_name or "";
          fsiblings = fcpu0.siblings or 0;
          fcores = fcpu0.cores or 0;
  /*nixfmt:enable*/
  hostThreadsPerCore = if (fsiblings > 0) && (fcores > 0) then fsiblings / fcores else null;
  cpuVendor =
    if hasInfix "AMD" fvendor then
      "amd"
    else if hasInfix "Intel" fvendor then
      "intel"
    else
      "";
in
{
  options = {
    hardware.cpu = {
      arch =
        let
          allowedArchs = [
            "x86_64"
            "aarch64"
          ];
          allowedArchsStr = concatStringsSep ", " allowedArchs;
        in
        mkOption {
          type = enum allowedArchs;
          default = hostArch; # Use host architecture as default
          description = "CPU architecture for the VM. Allowed values: ${allowedArchsStr}";
        };
      cores = mkOption {
        type = ints.positive;
        default = 2;
        description = "Number of cores allocated to the VM";
      };
      sockets = mkOption {
        type = ints.positive;
        default = 1;
        description = "Number of physical CPU sockets allocated to the VM";
      };
      threads = mkOption {
        type = nullOr ints.positive;
        default = hostThreadsPerCore; # Use host architecture as default
        description = "Number of threads per core";
      };
      vendor =
        let
          allowedVendors = [
            "amd"
            "intel"
          ];
          allowedVendorsStr = concatStringsSep ", " allowedVendors;
        in
        mkOption {
          type = nullOr (enum allowedVendors);
          default = cpuVendor;
          description = "CPU vendor. Allowed values: ${allowedVendorsStr}";
        };
      machine = mkOption {
        type = nullOr str;
        default = null;
        description = "Machine type for the VM (e.g., 'q35', 'pc')";
      };
    };
  };

  config = {
    _internalVmConfig.cpu = cfg.cpu;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

        inherit (nixVmLib.misc) getHostOS getHypervisorType getMachineType;

        hostOS = getHostOS hostSystem;
        hypervisorType = getHypervisorType hostOS hostArch vmCfg.cpu.arch;
        machineType = getMachineType vmCfg.cpu.machine vmCfg.cpu.arch;
        enableTopoext =
          vmCfg.cpu.arch == "x86_64"
          && vmCfg.cpu.vendor == "amd"
          && (vmCfg.cpu.threads != null && vmCfg.cpu.threads > 1);
      in
      {
        type = hypervisorType;

        cpu = {
          # Mimic host's physical CPU
          mode = "host-passthrough";
          check = "none";
          # Drop VM live-migration but increase performance
          migratable = false;
        }
        // optionalAttrs (vmCfg.cpu.threads != null) {
          topology = {
            cores = vmCfg.cpu.cores / vmCfg.cpu.threads;
            dies = 1;
            sockets = vmCfg.cpu.sockets;
            threads = vmCfg.cpu.threads;
          };
        }
        // optionalAttrs enableTopoext {
          feature = [
            {
              policy = "require";
              name = "topoext";
            }
          ];
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
