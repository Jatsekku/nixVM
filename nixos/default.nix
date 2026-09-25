{
  config,
  lib,
  pkgs,
  nixvirt,
  ...
}:

with lib;

let
  cfg = config.nix-vm;

  nixvirtLib = nixvirt.lib;

  vmSubmodule = types.submoduleWith {
    specialArgs = {
      inherit nixvirtLib;
      hostConfig = config; # Pass the outer host NixOS config here safely
    };
    modules = [
      ../modules/core.nix
    ];
  };
in
{
  options.nix-vm = {
    vms = mkOption {
      type = types.attrsOf vmSubmodule;
      default = { };
      description = "";
    };
  };

  config = {
    virtualisation.libvirt.enable = true;

    virtualisation.libvirt.connections."qemu:///system".domains = mapAttrsToList (name: vm: {
      definition = nixvirtLib.domain.writeXML vm._nixVirtSpecification // { inherit name} ;
    }) cfg.vms;
  };
}
