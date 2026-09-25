{ config, lib, ... }:
with lib;
with types;
let
  cfg = config.hardware.cpu;
in
{
  options = {
    hardware.cpu = {
      cores = mkOption {
        type = ints.positive;
        default = 2;
        description = "Number of vCPU cores allocated to the VM";
      };
    };
  };

  config._internalVmConfig = {
    cpu = {
      cores = cfg.cores;
    };
  };
}
