{ config, lib, pkgs, ... }:

{
  imports = [
    ../_common/nix.nix
    ../_linux/base.nix
    ../_linux/chrony.nix
    ../_linux/dnscrypt.nix
    ../_linux/no-sleep.nix
    ../_linux/fix/nftables.nix
    #../_linux/ui/sway.nix
    #../_linux/ui/gnome.nix
    #../_linux/docker.nix # imported in top level flake

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

  environment.persistence."/persist" = {
    directories = [
      "/etc/nixos"
      "/etc/ssh"
      "/var/log"

      # systemd machines
      "/etc/containers"
      "/var/lib/containers"
    ] ++ lib.optionals config.networking.wireless.iwd.enable [
      "/var/lib/iwd"
    ] ++ lib.optionals config.services.chrony.enable [
      "/var/lib/chrony"
    ] ++ lib.optionals config.services.k3s.enable [
      "/etc/rancher"
      "/var/lib/kubelet"
      "/var/lib/rancher"
    ] ++ lib.optionals config.virtualisation.docker.enable [
      "/var/lib/docker"
    ];

    files = [
      "/etc/machine-id"
    ];
  };
}
