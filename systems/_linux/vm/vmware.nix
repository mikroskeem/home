{ config, lib, ... }:

{
  virtualisation.vmware.guest.enable = true;
  environment.variables = lib.optionalAttrs config.virtualisation.vmware.guest.enable {
    "WLR_NO_HARDWARE_CURSORS" = "1";
  };
}
