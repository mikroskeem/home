{ config, lib, pkgs, ... }:

{
  imports = [
    ../_common/nix.nix
    ../_linux/base.nix
    ../_linux/chrony.nix
    ../_linux/dnscrypt.nix
    ../_linux/nix.nix
    ../_linux/no-sleep.nix
    ../_linux/fix/nftables.nix
    #../_linux/ui/sway.nix
    #../_linux/ui/gnome.nix

    ./hardware.nix
    ./users.nix
    #./steam.nix # enable if very bored
  ];

  system.stateVersion = "22.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "lachesis";
  networking.hostId = "007f0200";
  networking.useDHCP = false;

  networking.wireless.enable = false;
  networking.wireless.iwd.enable = true;
  networking.interfaces.enp4s0f2.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  time.timeZone = "Europe/Tallinn";

  boot.kernelPackages = pkgs.zfs.latestCompatibleLinuxPackages;

  security.sudo.wheelNeedsPassword = false;
  security.polkit.enable = true;

  virtualisation.podman.enable = true;

  nix.settings.trusted-users = [ "root" "@wheel" ];
}
