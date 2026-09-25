{ lib, pkgs }:
{
  disks = import ./disks.nix { inherit lib; };
  memory = import ./memory.nix { inherit lib; };
  misc = import ./misc.nix { inherit lib pkgs; };
  windows = import ./windows.nix { inherit lib pkgs; };
}
