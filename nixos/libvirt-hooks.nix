{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
with builtins;
with types;
let
  cfg = config.nix-vm;

  vmsHooks = mapAttrs (_: vm: vm._internalVmConfig.hooks) cfg.vms;
in
{
  config = {
    virtualisation.libvirtd.scopedHooks.qemu = {
      enable = true;
      perGuest = vmsHooks;
    };
  };
}
