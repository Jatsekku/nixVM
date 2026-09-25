{ lib }:
with builtins;
with lib;
with types;
let
  channelModule = submodule {
    options = {
      name = mkOption {
        type = nullOr str;
        default = "com.redhat.spice.0";
        description = "Target name identifier for the channel";
      };

      address = mkOption {
        type = nullOr str;
        default = null;
      };
    };
  };

  mkSpicevmcChannel =
    settings:
    let
      name = settings.name;
    in
    {
      type = "spicevmc";
      target = {
        type = "virtio";
      }
      // optionalAttrs (name != null) {
        inherit name;
      };
    };

  mkSpicevmcChannels =
    channels:
    let
      spicevmcChannels = filter (d: d ? spicevmc) channels;
    in
    {
      channel = map (d: mkSpicevmcChannel d.spicevmc) spicevmcChannels;
    };

  mkNixVirtSpec = channels: {
    devices = mkSpicevmcChannels channels;
  };

in
{
  inherit mkNixVirtSpec;
  module = channelModule;
}
