{
  lib,
}:
{
  mkOS = settings: {
    clock = {
      kvmclock = {
        present = true;
      };
    };
  };
}
