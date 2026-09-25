{ config, lib, ... }:
with lib;
with types;
let
  cfg = config.hardware.displays;

  displayType = submodule {
    options = {
      backend = mkOption {
        type = nullOr (enum [
          "dbus"
          "desktop"
          "egl-headless"
          "looking-glass"
          "rdp"
          "sdl"
          "spice"
          "vnc"
        ]);
        default = null;
        description = "The display backend technology";
      };
    };
  };
in
{
  options = {
    hardware.displays = mkOption {
      type = listOf displayType;
      default = [ ];
      description = "List of virtual displays provided for the VM.";
    };
  };
}
