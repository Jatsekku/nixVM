{ config, lib, ... }:
with lib;
with types;
let
  cfg = config.hardware.ram;

  nixVmLib = import ./../lib { inherit lib; };
in
{
  options = {
    hardware.ram = {
      amount = mkOption {
        type = str;
        default = "2G";
        description = "Amount of RAM allocated to the VM ('4MiB', '2GB', '12.5%')";
      };
    };
  };

  config._internalVmConfig = {
    ram = {
      amount = nixVmLib.parseMemory cfg.amount;
    };
  };
}
