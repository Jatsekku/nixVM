{ inputs, ... }:
{
  den.aspects.vms.windows-example = {
    nixos = {
      imports = [ inputs.nix-vm.nixosModules.default ];

      nix-vm.vms.windows-example = {
        hardware = {
          cpu = {
            cores = 4;
            arch = "x86_64";
            # machine = "q35"
          };
          ram = {
            amount = "8G";
          };
          disks = [
            { path = "/var/lib/libvirt/images/win10-disk.qcow2"; }
          ];
          displays = [
            { backend = "spice"; }
            { backend = "loooking-glass"; }
          ];
        };
      };
    };
  };
}
