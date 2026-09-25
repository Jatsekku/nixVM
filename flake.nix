{
  description = "A collection for VM modules";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # LibVirt domain management for Nix.
    nixvirt = {
      url = "github:AshleyYakeley/NixVirt";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nixvirt,
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
