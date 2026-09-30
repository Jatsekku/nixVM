{
  lib,
  pkgs,
}:
{
  _nixVirtSpec = {
    os = {
      # UEFI
      loader = {
        readonly = true;
        type = "pflash";
        path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
      };
      nvram = {
        template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
      };
    };
  };
}
