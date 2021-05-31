{ config, lib, ... }:

{
  # TODO(2021-05-13) - open-vm-tools does not build
  nixpkgs.overlays = [
    (self: super: let
      olderPkgs = import (builtins.fetchTarball https://github.com/r-ryantm/nixpkgs/archive/63d650556b6917b3a4075f81bd7cdff3d8f3bb40.tar.gz) {};
    in {
      open-vm-tools = olderPkgs.open-vm-tools;
    })
  ];

  virtualisation.vmware.guest.enable = true;
  environment.variables = lib.optionalAttrs (config.virtualisation.vmware.guest.enable) {
    "WLR_NO_HARDWARE_CURSORS" = "1";
  };
}
