{ lib }:
with builtins;
with lib;
with types;
let
  networkModule = submodule {
    options = {
      deviceModel = mkOption {
        type = nullOr (enum [
          "virtio"
          "e1000e"
        ]);
        default = "e1000e";
        description = "The network device model driver exposed to the guest.";
      };
      macAddress = mkOption {
        type = nullOr str;
        default = null;
        description = "MAC address for the interface.";
      };
      source = mkOption {
        type = str;
        default = "default";
        description = "The name of the libvirt network to attach to.";
      };
    };
  };
in
{
  module = networkModule;
  mkInterface =
    settings:
    let
      model = if settings.deviceModel != null then { type = settings.deviceModel; } else null;
      mac = if settings.macAddress != null then { address = settings.macAddress; } else null;
      source = {
        network = settings.source;
      };
    in
    {
      devices = {
        interface = {
          type = "network";
          inherit source;
        }
        // optionalAttrs (model != null) { inherit model; }
        // optionalAttrs (mac != null) { inherit mac; };
      };
    };
}
