{
  description = "A collection for VM modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NixOS module for managing per-VM libvirt hooks.
    libvirt-hooks = {
      url = "github:Jatsekku/libvirt-hooks";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # NixOS module for Looking Glass.
    looking-glass = {
      url = "github:Jatsekku/looking-glass";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # LibVirt domain management for Nix.
    nixvirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # VFIO stealth tuning for NixOS.
    vfio-stealth = {
      url = "github:Daaboulex/vfio-stealth-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvirt,
      looking-glass,
      vfio-stealth,
      libvirt-hooks,
      ...
    }:
    let
      # List of all supported systems
      supportedSystems = nixpkgs.lib.systems.flakeExposed;

      # Function for providing system-specific attributes
      forEachSupportedSystem =
        f:
        nixpkgs.lib.genAttrs supportedSystems (
          system:
          f {
            # Nixpkgs configured per system
            pkgs = import nixpkgs {
              inherit system;
              # Allow usage of unfree packages
              config.allowUnfree = true;
            };
          }
        );
    in
    {
      nixosModules = rec {
        nix-vm = {
          imports = [
            ./nixos
            nixvirt.nixosModules.default
            looking-glass.nixosModules.default
            vfio-stealth.nixosModules.default
            libvirt-hooks.nixosModules.default
          ];
          _module.args = { inherit nixvirt; };
        };
        default = nix-vm;
      };

      checks = forEachSupportedSystem (
        { pkgs, ... }:
        {
          basic = import ./tests/integration/nixos/basic.nix { inherit pkgs self; };
        }
      );

      # Set formatter for Nix
      formatter = forEachSupportedSystem ({ pkgs }: pkgs.nixfmt-tree);
    };
}
