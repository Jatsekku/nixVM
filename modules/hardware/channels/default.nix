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

  backends = {
    #file = import ./file.nix {inherit lib; };
    #pty = import ./pty.nix {inherit lib; };
    #qemu-vdagent = import ./qemu-vdagnet.nix {inherit lib; };
    spicevmc = import ./spicevmc.nix { inherit lib; };
    #unix = import ./unix.nix {inherit lib; };
  };

  channelType = submodule {
    options = {
      spicevmc = mkOption {
        type = nullOr backends.spicevmc.module;
        default = null;
        description = "Spicevmc channel settings.";
      };
    };
  };
in
{
  options = {
    hardware.channels = mkOption {
      type = listOf channelType;
      default = [ { spicevmc = { }; } ];
      description = "List of communication channels allocated to the VM";
    };
  };

  config = {
    _internalVmConfig.channels = cfg.channels;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;
      in
      foldl' lib.recursiveUpdate { } (map (b: b.mkNixVirtSpec vmCfg.channels) (attrValues backends));
  };
}
