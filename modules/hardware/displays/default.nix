{
  config,
  hostConfig,
  lib,
  name,
  pkgs,
  ...
}:
with builtins;
with lib;
with types;
let
  cfg = config.hardware;

  backends = {
    looking-glass = import ./looking-glass.nix { inherit lib hostConfig name; };
    spice = import ./spice.nix { inherit lib; };
  };

  displayType = submodule {
    options = {
      spice = mkOption {
        type = nullOr backends.spice.module;
        default = null;
        description = "Spice display backend settings.";
      };

      looking-glass = mkOption {
        type = nullOr backends.looking-glass.module;
        default = null;
        description = "Looking-glass display backend settings.";
      };
    };
  };

  filterEmptyBackends =
    displays:
    map (
      display:
      let
        filtered = lib.filterAttrs (_: val: val != null) display;
        backendNames = attrNames filtered;
      in
      if length backendNames != 1 then
        throw "Each display must have exactly one backend defined!"
      else
        filtered
    ) displays;

in
{
  options = {
    hardware.displays = mkOption {
      type = listOf displayType;
      default = [ { spice = { }; } ];
      description = "List of virtual displays provided for the VM.";
    };
  };

  config = {
    _internalVmConfig.displays = filterEmptyBackends cfg.displays;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;
      in
      foldl' lib.recursiveUpdate { } (map (b: b.mkNixVirtSpec vmCfg.displays) (attrValues backends));
  };
}
