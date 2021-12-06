{ config, lib, pkgs, ... }:

{
  imports = [
    ../_common/nix.nix
    ../_linux/base.nix
    ../_linux/chrony.nix
    ../_linux/dnscrypt.nix
    (import ../_linux/docker.nix { })
    ../_linux/no-sleep.nix
    ../_linux/fix/nftables.nix
    #../_linux/ui/sway.nix
    #../_linux/ui/gnome.nix

    ./hardware.nix
    ./users.nix
    #./steam.nix # enable if very bored
  ];

  system.stateVersion = "21.05";

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];

  networking.hostName = "meeksorkim2";
  networking.hostId = "007f0200";
  networking.useDHCP = false;

  networking.wireless.enable = false;
  networking.wireless.iwd.enable = true;
  networking.interfaces.enp4s0f2.useDHCP = true;
  networking.interfaces.wlan0.useDHCP = true;

  time.timeZone = "Europe/Tallinn";

  boot.kernelPackages = pkgs.linuxPackages_latest;
  nixpkgs.config.allowBroken = true; # zfs + linuxPackages_latest, pray that it'll compile and sometimes it actually works.

  virtualisation.podman.enable = true;
}
