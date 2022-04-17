{ config, lib, pkgs, kernel-patches, ... }:

{
  imports = [
    ../_common/nix.nix
    ../_linux/base.nix
    ../_linux/chrony.nix
    ../_linux/dnscrypt.nix
    (import ../_linux/docker.nix { })
    ../_linux/nix.nix
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
  boot.kernelPatches = [
    {
      name = "disable-bridge-state-logging-by-default";
      patch = "${kernel-patches}/logging/disable-bridge-state-logging-by-default.patch";
    }
    {
      name = "remove-netdev-rename-and-promiscuous-mode-messages";
      patch = "${kernel-patches}/logging/remove-netdev-rename-and-promiscuous-mode-messages.patch";
    }
    {
      name = "decrease-certain-ipv6-addrconf-message-log-levels";
      patch = "${kernel-patches}/logging/decrease-certain-ipv6-addrconf-message-log-levels.patch";
    }
    {
      name = "drop-useless-cgroup-mount-options-message";
      patch = "${kernel-patches}/logging/drop-useless-cgroup-mount-options-message.patch";
    }
    {
      name = "binfmt_misc-cleanup-on-filesystem-umount";
      patch = "${kernel-patches}/binfmt_misc-sandbox/0001-binfmt_misc-cleanup-on-filesystem-umount.patch";
    }
    {
      name = "binfmt_misc-enable-sandboxed-mounts";
      patch = "${kernel-patches}/binfmt_misc-sandbox/0002-binfmt_misc-enable-sandboxed-mounts.patch";
    }
  ];

  security.sudo.wheelNeedsPassword = false;

  virtualisation.podman.enable = true;

  nix.settings.trusted-users = [ "root" "@wheel" ];
}
