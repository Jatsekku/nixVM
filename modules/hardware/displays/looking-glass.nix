{
  lib,
  hostConfig,
  name,
}:
with lib;
with builtins;
with types;
let
  permissionsModule = submodule {
    options = {
      user = mkOption {
        type = str;
        default = "root";
        description = "Owner of the shared memory";
      };
      group = mkOption {
        type = str;
        default = "root";
        description = "Group of the shared memory";
      };
      mode = mkOption {
        type = str;
        default = "0600";
        description = "Mode of the shared memory";
      };
    };
  };

  /*nixfmt:disable*/
  # 'f' stands for facter
  freport = hostConfig.nix-vm.facter.report;
    fhardware = freport.hardware or { };
      fmonitor = fhardware.monitor or [ ];
        fmonitor0 = if fmonitor != [ ] then head fmonitor else { };
          fdetail = fmonitor0.detail or { };
  /*nixfmt:enable*/
  monitorWidth = fdetail.width or 1920;
  monitorHeight = fdetail.height or 1080;

  lookingGlassModule = submodule {
    options = {
      width = mkOption {
        type = ints.unsigned;
        default = monitorWidth;
        description = "Display width in pixels";
      };

      height = mkOption {
        type = ints.unsigned;
        default = monitorHeight;
        description = "Display height in pixels";
      };

      bpp = mkOption {
        type = ints.positive;
        default = 4;
        description = "Bytes per pixel";
      };

      permissions = mkOption {
        type = permissionsModule;
        description = "Permissions of underlying shared memory for virtual display";
      };

      kvmfr = mkOption {
        type = bool;
        default = true;
        description = "Whether to use KVMFR for this display";
      };

      shared = mkOption {
        type = bool;
        default = true;
        description = "Whether display should be sahred aacross VM";
      };
    };
  };

  mkLookingGlassDisplays = _:
  let
      # It's global resource so has to be pulled from top entry point
      nixVirtSettings = hostConfig.nix-vm.hostResources.looking-glass.nixVirtSettingsFor.${name};
      qemuCommandLineArgs = concatMap (s: s.qemuCommandLineArgs or [ ]) nixVirtSettings;
      sharedMemory = concatMap (s: s.sharedMemory or [ ]) nixVirtSettings;
    in
    { }
    // optionalAttrs (qemuCommandLineArgs != [ ]) { qemu-commandline = { arg = qemuCommandLineArgs;}; }
    // optionalAttrs (sharedMemory != [ ]) {
      devices = {
        shmem = sharedMemory;
      };
    };

in
{
  module = lookingGlassModule;
  mkNixVirtSpec = mkLookingGlassDisplays;
}
