{
  config,
  lib,
  pkgs,
  hostConfig,
  ...
}:
with lib;
with types;
{
  imports = import ./module-list.nix;

  options = {
    _internalVmConfig = mkOption {
      type = attrs;
      default = { };
      internal = true;
    };

    _nixVirtSpecification = mkOption {
      type = attrs;
      default = { };
      internal = true;
    };
  };

  config = {
    _nixVirtSpecification = {
      name = "validBareMinimum";
      type = "kvm";
      uuid = "fbe91dfd-fdd9-2e31-1420-50ebf6599a91";

      memory = {
        count = 1;
        unit = "GiB";
      };

      os = {
        type = "hvm";
      };
    };
  };
}
