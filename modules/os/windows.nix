{
  lib,
  pkgs,
}:
{
  mkOS = settings: {
    clock = {
      hypervclock = {
        present = true;
      };
    };

    features = {
      hyperv = {
        mode = "custom";
        relaxed = {
          state = true;
        };
        vapic = {
          state = true;
        };
        spinlocks = {
          state = true;
          retries = 8191;
        };
      };
    };

    os = {
      loader = {
        readonly = true;
        type = "pflash";
        path = "${pkgs.OVMFFull.fd}/FV/OVMF_CODE.ms.fd";
      };
      nvram = {
        template = "${pkgs.OVMFFull.fd}/FV/OVMF_VARS.ms.fd";
        path = settings.nvramPath;
      };
    };
  };
}
