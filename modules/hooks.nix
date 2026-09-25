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
  cfg = config;

  hooksNames = [
    "prepare"
    "start"
    "started"
    "stopped"
    "release"
  ];

  hookPhasesModule = submodule {
    options = {
      begin = mkOption {
        type = nullOr (oneOf [
          str
          (listOf str)
        ]);
        default = null;
        description = "Path(s) to script(s) executed at the begin phase.";
      };

      end = mkOption {
        type = nullOr (oneOf [
          str
          (listOf str)
        ]);
        default = null;
        description = "Path(s) to script(s) executed at the end phase.";
      };
    };
  };

  hooksModule = submodule {
    options = listToAttrs (
      map (hookName: {
        name = hookName;
        value = mkOption {
          type = hookPhasesModule;
          default = { };
          description = "Hook type";
        };
      }) hooksNames
    );
  };
in
{
  options = {
    hooks = mkOption {
      type = hooksModule;
      default = { };
      description = "QEMU hooks";
    };
  };

  config = {
    _internalVmConfig.hooks = cfg.hooks;
  };
}
