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

  vncOptions = {
    options = {
      port = mkOption {
        type = nullOr int;
        default = null;
        description = "Port for the VNC server (do not set for auto)";
      };

      websocket = mkOption {
        type = nullOr int;
        default = null;
        description = "WebSocket port number for HTML5 VNC clients";
      };

      keymap = mkOption {
        type = nullOr str;
        default = null;
        description = "Keymap to use for the VNC server";
      };

      listen = mkOption {
        type = submodule listenModule;
        default = { };
        description = "Listen configuration for the VNC server";
      };

      passwd = mkOption {
        type = nullOr str;
        default = null;
        description = "Optional connection password";
      };
    };
  };
in
{
  validKeys = (attrNames vncOptions.options);
  module = submodule vncOptions;

  mkGraphicVnc =
    display:
    let
      port = display.port;
      tlsPort = display.tlsPort;
      websocket = display.websocket;
      passwd = display.passwd;
      keymap = display.keymap;

      listenType = display.listen.type;
      listenSource = display.listen.source;
      listen = {
        type = listenType;
      }
      // optionalAttrs (listenType != "none" && listenSource != null) {
        "${listenType}" = listenSource;
      };

    in
    {
      graphics = mergeAttrsList [
        {
          type = "vnc";
          inherit listen;
        }
        /*nixfmt:disable*/
        (if passwd != null then { inherit passwd; } else { })
        (if keymap != null then { inherit keymap; } else { })
        (if tlsPort != null then { tlsPort = toString tlsPort; } else { })
        (if websocket != null then { websocket = toString websocket; } else { })
        (if port != null then { port = toString port; autoport = "no"; } else { autoport = "yes"; })
        /*nixfmt:enable*/
      ];
    };
}
