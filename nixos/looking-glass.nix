{
  config,
  lib,
  ...
}:
with lib;
with builtins;
with types;
let
  cfg = config.nix-vm;

  mkLookingGlassDisplays =
    vms:
    let
      # Get all Looking Glass displays from specified vm
      getVmLgDisplays =
        { vms, vmName }:
        let
          allDisplays = vms.${vmName}._internalVmConfig.displays;
          lgDisplays = filter (d: d ? looking-glass) allDisplays;
        in
        map (d: d.looking-glass) lgDisplays;

      vmsWithLgDisplays = mapAttrs (vmName: vmConfig: getVmLgDisplays { inherit vms vmName; }) vms;

      # Inject VM ownership into each display as a list
      vmsWithOwnedLgDisplays = mapAttrs (
        vmName: lgDisplays: map (display: display // { ownership = [ vmName ]; }) lgDisplays
      ) vmsWithLgDisplays;

      # Flatten into single list
      allLgDisplays = concatLists (attrValues vmsWithOwnedLgDisplays);

      # Extract shared/isolated
      partitionedLgDisplays = partition (d: d.shared or false) allLgDisplays;
      isolatedLgDisplays = partitionedLgDisplays.wrong;
      sharedLgDisplays = partitionedLgDisplays.right;

      # Handle isolated displays
      isolatedLgDisplaysFinal = listToAttrs (
        imap0 (
          idx: d:
          let
            vmName = head d.ownership;
            cleanDisplay = removeAttrs d [ "shared" ];
          in
          nameValuePair "isolated-lg-${vmName}-${toString idx}" cleanDisplay
        ) isolatedLgDisplays
      );

      # Extract kvmfr/non-kvmfr
      partitionedSharedLgDisplays = partition (d: d.kvmfr or false) sharedLgDisplays;
      sharedKvmfrLgDisplays = partitionedSharedLgDisplays.right;
      sharedNonKvmfrLgDisplays = partitionedSharedLgDisplays.wrong;

      mkSharedDisplays =
        displays:
        if displays == [ ] then
          { }
        else
          let
            ownersLists = attrValues (groupBy (d: head d.ownership) displays);
            sharedSlotsCount = foldl' max 0 (map length ownersLists);
            slots = genList (_: { }) sharedSlotsCount;

            getDisplayAtSlot = list: idx: if length list > idx then [ (elemAt list idx) ] else [ ];
          in
          listToAttrs (
            imap0 (
              idx: _:
              let
                displaysAtSlot = concatMap (list: getDisplayAtSlot list idx) ownersLists;

                biggestDisplay = head (
                  sort (a: b: (a.width * a.height * a.bpp) > (b.width * b.height * b.bpp)) displaysAtSlot
                );

                cleanBiggestDisplay = removeAttrs biggestDisplay [ "shared" ];
              in
              {
                name = "shared-lg-${toString idx}";
                value = cleanBiggestDisplay // {
                  ownership = map (d: head d.ownership) displaysAtSlot;
                };
              }
            ) slots
          );

      sharedKvmfrLgDisplaysFinal = mkSharedDisplays sharedKvmfrLgDisplays;
      sharedNonKvmfrLgDisplaysFinal = mkSharedDisplays sharedNonKvmfrLgDisplays;
    in
    rec {
      withOwnership =
        isolatedLgDisplaysFinal // sharedKvmfrLgDisplaysFinal // sharedNonKvmfrLgDisplaysFinal;
      plain = mapAttrs (name: display: removeAttrs display [ "ownership" ]) withOwnership;
    };

  lookingGlassDisplays = mkLookingGlassDisplays cfg.vms;
in
{
  config = lib.mkIf (lookingGlassDisplays.plain != { }) {
    virtualisation.looking-glass = {
      enable = true;
      enableClient = mkDefault true;
      displays = lookingGlassDisplays.plain;
    };

    nix-vm.hostResources = {
      looking-glass.nixVirtSettingsFor = mapAttrs (
        vmName: _:
        let
          nixVirtSettingsFor =
            displayName: config.virtualisation.looking-glass.nixVirtSettingsFor.${displayName};
          displaysNames = attrNames (
            filterAttrs (_: d: elem vmName d.ownership) lookingGlassDisplays.withOwnership
          );
        in
        map (dName: nixVirtSettingsFor dName) displaysNames
      ) cfg.vms;
    };
  };
}
