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
    looking-glass = import ./looking-glass.nix { inherit lib hostConfig; };
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
    displays: map (display: lib.filterAttrs (name: val: val != null) display) displays;

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

        mkGraphic =
          display:
          let
            attrsNames = attrNames display;
            backendName =
              if length attrsNames != 1 then
                throw "Each display must have exactly one backend defined!"
              else
                head attrsNames;
            settings = display.${backendName};
            builder = backends.${backendName}.mkGraphic;
          in
          builder settings;

        mkGraphics = displays: lib.foldl' (acc: x: acc // x) { } (map mkGraphic displays);
      in
      mkGraphics vmCfg.displays;
  };
}
