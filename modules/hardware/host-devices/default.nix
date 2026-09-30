{
  config,
  hostConfig,
  lib,
  pkgs,
  ...
}:
with builtins;
with lib;
with types;
let
  cfg = config.hardware;

  nixVmLib = import ./../../lib { inherit lib pkgs; };
  inherit (nixVmLib.misc) deepFindFirst deepFindAll;

  /*nixfmt:disable*/
  # 'f' stands for facter
  freport = hostConfig.nix-vm.facter.report;
    fhardware = freport.hardware or { };
  /*nixfmt:enable*/

  getIommuId =
    addressHex:
    let
      match = deepFindFirst (x: (isAttrs x) && ((x.sysfs_bus_id or "") == addressHex)) fhardware;
      iommuId = if match != null then match.sysfs_iommu_group_id else null;
    in
    iommuId;

  getIommuSiblings =
    iommuGroup:
    let
      matches = deepFindAll (
        x: (isAttrs x) && ((x.sysfs_iommu_group_id or (-1)) == iommuGroup)
      ) fhardware;
      addresses = if matches != [ ] then map (m: m.sysfs_bus_id) matches else [ ];
    in
    addresses;

  parseHostDevice =
    address:
    let
      pciMatch = match "^([0-9a-fA-F]{4}:)?([0-9a-fA-F]{2}):([0-9a-fA-F]{2})\\.([0-9a-fA-F]{1})$" address;
      usbMatch = match "^([0-9a-fA-F]{4}):([0-9a-fA-F]{4})$" address;
    in
    if pciMatch != null then
      rec {
        type = "pci";
        domain =
          let
            d = elemAt pciMatch 0;
          in
          if d != null then fromHexString (substring 0 4 d) else 0;
        bus = fromHexString (elemAt pciMatch 1);
        slot = fromHexString (elemAt pciMatch 2);
        function = fromHexString (elemAt pciMatch 3);
        addressHex =
          let
            hex = n: toLower (toHexString n);
            pad = w: s: fixedWidthString w "0" s;
          in
          "${pad 4 (hex domain)}:${pad 2 (hex bus)}:${pad 2 (hex slot)}.${hex function}";
        iommuId = getIommuId addressHex;
      }
    else if usbMatch != null then
      {
        type = "usb";
        vendorId = lib.fromHexString (builtins.elemAt usbMatch 0);
        productId = lib.fromHexString (builtins.elemAt usbMatch 1);
      }
    else
      throw "Unable to parse device address: ${address}";

  parseHostDevices = devices: map (d: parseHostDevice d) devices;

  parsedHostDevices = parseHostDevices cfg.hostDevices.devices;
  parsedHostPciDevices = filter (d: d.type == "pci") parsedHostDevices;
  parsedHostUsbDevices = filter (d: d.type == "usb") parsedHostDevices;

  iommuIds = lists.unique (map (d: d.iommuId) parsedHostPciDevices);
  iommuSiblings = lists.unique (concatMap (id: getIommuSiblings id) iommuIds);

  allPciDevices =
    if (cfg.hostDevices.includeIommuSiblings == true) then
      parseHostDevices iommuSiblings
    else
      parsedHostPciDevices;

  allDevices = parsedHostUsbDevices ++ allPciDevices;

in
{
  options = {
    hardware.hostDevices = {
      devices = mkOption {
        type = listOf str;
        default = [ ];
        description = "List of hardware devices to pass through";
      };

      includeIommuSiblings = mkOption {
        type = bool;
        default = true;
        description = "Whether to automatically include other devices sharing the same IOMMU group";
      };
    };
  };

  config = {
    _internalVmConfig.hostDevices = {
      devices = allDevices;
    };

    _nixVirtSpec =
      let
        vmCfg = config._internalVmConfig;

        mkHostUsbDevice = device: {
          type = "usb";
          mode = "subsystem";
          source = {
            vendor.id = device.vendorId;
            product.id = device.productId;
          };
        };

        mkHostPciDevice = device: {
          type = "pci";
          mode = "subsystem";
          managed = true;
          source.address = {
            inherit (device)
              domain
              bus
              slot
              function
              ;
          };
        };

        mkHostDevice =
          device:
          let
            handlers = {
              pci = mkHostPciDevice;
              usb = mkHostUsbDevice;
            };
          in
          if handlers ? ${device.type} then
            handlers.${device.type} device
          else
            throw "Unsupported device type: ${device.type}";

        mkHostDevices = hostDevices: flatten (map mkHostDevice hostDevices);
      in
      {
        devices = {
          hostdev = mkHostDevices vmCfg.hostDevices.devices;
        };
      };
  };
}
