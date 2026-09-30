{ lib }:
with builtins;
with lib;
with types;
let
  listenModule = submodule {
    options = {
      type = mkOption {
        type = enum [
          "address"
          "network"
          "socket"
          "none"
        ];
        default = "none";
        description = "The listen type for the graphics server";
      };
      source = mkOption {
        type = nullOr str;
        default = null;
        description = "IP address/network name/socket to listen at";
      };
    };
  };

  spiceOptions = {
    options = {
      port = mkOption {
        type = nullOr int;
        default = null;
        description = "Port for the graphics server (do not set for auto)";
      };

      listen = mkOption {
        type = listenModule;
        default = { };
        description = "Listen configuration for the graphics server";
      };

      passwd = mkOption {
        type = nullOr str;
        default = null;
        description = "Optional connection password";
      };

      imageCompression = mkOption {
        type = enum [
          "auto_glz"
          "auto_lz"
          "quic"
          "glz"
          "lz"
          "off"
        ];
        default = "off";
        description = "Image compression setting for SPICE";
      };

      glRenderNode = mkOption {
        type = nullOr str;
        default = null;
        description = "Path to specific DRM render node (e.g. /dev/dri/renderD128 or auto)";
      };
    };
  };

  defaultSettings = mapAttrs (name: opt: opt.default) spiceOptions.options;
in
{
  module = submodule spiceOptions;
  mkGraphic =
    settings:
    let
      port = settings.port;
      passwd = settings.passwd;
      image = {
        compression = settings.imageCompression;
      };

      rendernode = settings.glRenderNode;
      gl = {
        enable = (rendernode != null);
      }
      // optionalAttrs (rendernode != "auto") {
        inherit rendernode;
      };

      listenType = settings.listen.type;
      listenSource = settings.listen.source;
      listen = {
        type = listenType;
      }
      // optionalAttrs (listenType != "none" && listenSource != null) {
        "${listenType}" = listenSource;
      };

    in
    {
      devices = {
        graphics = mergeAttrsList [
          {
            type = "spice";
            inherit listen image gl;
          }
        /*nixfmt:disable*/
        (if passwd != null then { inherit passwd; } else { })
        (if port != null then { inherit port; autoport = false; } else { autoport = true; })
        /*nixfmt:enable*/
        ];
      };
    };
}
