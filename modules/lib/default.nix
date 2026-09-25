{ lib }:
let
  memory = import ./memory.nix { inherit lib; };
in
memory
