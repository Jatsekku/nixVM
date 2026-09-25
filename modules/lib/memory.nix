{ lib }:
with lib;
with builtins;
{
  parseMemory =
    arg:
    let
      trimmed = strings.trim arg;
      matched = match "^([0-9]+\\.[0-9]+|[0-9]+)[[:space:]]*([a-zA-Z]+|%)?$" trimmed;

      num =
        if matched != null then
          # Int or float
          fromJSON (elemAt matched 0)
        else
          throw "Invalid format: '${arg}'. Expected a number followed by a valid unit ('4MiB', '2GB', '10.5%').";

      unit = if (matched != null) && (elemAt matched 1 != null) then (elemAt matched 1) else "";

      # https://libvirt.org/formatdomain.html#memory-allocation
      /*nixfmt:disable*/
      allowedUnits = [
        "b" "bytes"

        "k" "KiB"   # 2^10 bytes
        "M" "MiB"   # 2^20 bytes
        "G" "GiB"   # 2^30 bytes
        "T" "TiB"   # 2^40 bytes

        "KB"        # 10^3 bytes
        "MB"        # 10^6 bytes
        "GB"        # 10^9 bytes
        "TB"        # 10^12 bytes

        "%"
      ];
      /*nixfmt:enable*/

      allowedUnitsStr = concatStringsSep ", " allowedUnits;

      output =
        if !(elem unit allowedUnits) then
          throw "Invalid unit: '${unit}'. Valid units are: ${allowedUnitsStr}."
        else if (unit != "%") && (!isInt num) then
          throw "Value for unit '${unit}' must be an integer (got: ${num})."
        else
          {
            count = num;
            unit = unit;
          };
    in
    output;
}
