{ lib, hostConfig }:
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
          detail = fmonitor0.detail or { };
            monitorWidth = detail.width or 1920;
            monitorHeight = detail.height or 1080;
  /*nixfmt:enable*/

  lookingGlassOptions = {
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
    };
  };
in
{
  module = submodule lookingGlassOptions;
  mkGraphic = settings: { };
}
