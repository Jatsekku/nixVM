{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}:
with lib;
with builtins;
with types;
let
  cfg = config.hardware.ram;
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

  config = {
    _internalVmConfig.ram =
      let
        nixVmLib = import ./../lib { inherit lib pkgs; };
        parseMemory = nixVmLib.memory.parseMemory;
        parsedMemory = parseMemory cfg.amount;
      in
      {
        amount = parsedMemory;
      };

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

      /*nixfmt:disable*/
      # 'f' stands for facter
      freport = hostConfig.nix-vm.facter.report;
        fhardware = freport.hardware or { };
          fmemory = fhardware.memory or [ ];
            # TODO: Check if I can blindly reference fist node
            fmemory0 = if fmemory != [] then head fmemory else { };
              resources = fmemory0.resources or [ ];
                resources0 = if resources != [] then head resources else { };
                  hostRamBytes = resources0.range or null;
      /*nixfmt:enable*/
      in
      {
        memory =
          if vmCfg.ram.amount.unit != "%" then
            {
              count = vmCfg.ram.amount.count;
              unit = vmCfg.ram.amount.unit;
            }
          else if hostRamBytes == null then
            throw "Unable to establish host RAM amount"
          else
            {
              count = floor ((hostRamBytes * vmCfg.ram.amount.count) / 100.0);
              unit = "bytes";
            };
      };
  };
}
