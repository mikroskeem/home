{ config, pkgs, ... }:

{
  virtualisation.lxc = {
    enable = true;
    lxcfs.enable = true;
    defaultConfig = "lxc.include = ${pkgs.lxcfs}/share/lxc/config/common.conf.d/00-lxcfs.conf";
  };
  virtualisation.lxd.enable = true;
}
