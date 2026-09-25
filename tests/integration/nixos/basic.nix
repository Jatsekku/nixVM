{ pkgs, self, ... }:

pkgs.testers.nixosTest {
  name = "nixos-basic";

  nodes.machine = { config, lib, ... }: {
    # Import exactly as a target user would
    imports = [ self.nixosModules.default ];

    virtualisation.memorySize = 2048;

    # Ensure libvirtd service is active in the test node to manage domains
    virtualisation.libvirtd.enable = true;

    # Define a VM using the options interface
    nix-vm.vms."my-vm" = {
      hardware.ram.amount = "4G";
    };

    assertions = [
      {
        assertion = builtins.hasAttr "_internalVmConfig" config.nix-vm.vms."my-vm";
        message = "_internalVmConfig missing on nix-vm.vms.'my-vm'!";
      }
      {
        assertion = builtins.hasAttr "ram" config.nix-vm.vms."my-vm"._internalVmConfig;
        message = "_internalVmConfig failed to capture RAM configuration for 'my-vm'!";
      }
    ];
  };

  testScript = ''
    machine.wait_for_unit("multi-user.target")
    machine.wait_for_unit("libvirtd.service")

    # Query Libvirt for the generated domain XML and print it out
    xml_output = machine.succeed("virsh dumpxml my-vm")
    print("--- Generated Libvirt XML Start ---")
    print(xml_output)
    print("--- Generated Libvirt XML End ---")

    # Assert that the XML contains the correct domain name and metadata
    assert "<name>my-vm</name>" in xml_output, "VM name missing from generated XML!"
    print("Assertion passed: XML successfully generated, written, and loaded into Libvirt!")
  '';
}
