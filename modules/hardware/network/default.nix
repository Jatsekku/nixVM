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

  nixVmLib = import ./../lib { inherit lib pkgs; };

  sources = {
    #bridge = import ./bridge.nix;
    #direct = import ./direct.nix;
    network = import ./network.nix { inherit lib; };
    #vdpa = import ./vdpa.nix
  };

  interfaceType = submodule {
    options = {
      #bridge = mkOption {
      #  type = nullOr sources.bridge.module;
      #  default = null;
      #  description = "Bridge network interface settings.";
      #};

      #direct = mkOption {
      #  type = nullOr sources.direct.module;
      #  default = null;
      #  description = "Direct network interface settings.";
      #};

      network = mkOption {
        type = nullOr sources.network.module;
        default = null;
        description = "Virtual network interface settings.";
      };

      #vdpa = mkOption {
      #  type = nullOr sources.vdpa.module;
      #  default = null;
      #  description = "VDPA network interface settings.";
      #};
    };
  };

  filterEmptySources = sources: map (source: lib.filterAttrs (name: val: val != null) source) sources;

in
{
  options = {
    hardware.network = {
      interfaces = mkOption {
        type = listOf interfaceType;
        default = [ { network = { }; } ];
        description = "List of network interfaces for VM";
      };
    };
  };

  config = {
    _internalVmConfig.interfaces = filterEmptySources cfg.network.interfaces;

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

        mkInterface =
          interface:
          let
            attrsNames = attrNames interface;
            sourceName =
              if length attrsNames != 1 then
                throw "Each interface must have exactly one source defined!"
              else
                head attrsNames;
            settings = interface.${sourceName};
            builder = sources.${sourceName}.mkInterface;
          in
          builder settings;

        mkInterfaces = interfaces: lib.foldl' (acc: x: acc // x) { } (map mkInterface interfaces);
      in
      mkInterfaces vmCfg.interfaces;
  };
}
