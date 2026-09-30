{ pkgs, lib }:
with builtins;
with lib;
rec {
  # Helper generating UUID based on string
  mkUuid =
    string:
    let
      hash = hashString "md5" string;
      sub = l: r: substring l r hash;
    in
    "${sub 0 8}-${sub 8 4}-${sub 12 4}-${sub 16 4}-${sub 20 12}";

  # Host OS detection
  getHostOS =
    system:
    if match ".*-linux" system != null then
      "linux"
    else if match ".*-darwin" system != null then
      "darwin"
    else
      "unknown";

  # Host architecture detection
  getHostArch =
    system:
    if match "x86_64-.*" system != null then
      "x86_64"
    else if match "aarch64-.*" system != null then
      "aarch64"
    else
      "";

  # Hypervisor type selection
  getHypervisorType =
    hostOS: hostArch: arch:
    if hostOS == "linux" && arch == hostArch then
      "kvm"
    else if hostOS == "darwin" && arch == hostArch then
      "hvf"
    else
      "qemu";

  # Machine type selection
  getMachineType =
    machineType: arch:
    if machineType != null then
      machineType
    else if arch == "aarch64" then
      "virt"
    else
      "q35";

  deepFindFirst =
    p: node:
    if p node then
      node
    else
      let
        kids =
          if isList node then
            node
          else if isAttrs node then
            attrValues node
          else
            [ ];

        searchKids =
          cs:
          if cs == [ ] then
            null
          else
            let
              res = deepFindFirst p (head cs);
            in
            if res != null then res else searchKids (tail cs);
      in
      searchKids kids;

  deepFindAll =
    p: node:
    let
      # If the current node matches, include it in a list; otherwise empty
      current = if p node then [ node ] else [ ];

      # Extract children if it's a list or attrset
      kids =
        if isList node then
          node
        else if isAttrs node then
          attrValues node
        else
          [ ];
    in
    # Combine current match (if any) with all matches found deeper in the tree
    current ++ concatMap (deepFindAll p) kids;
}
