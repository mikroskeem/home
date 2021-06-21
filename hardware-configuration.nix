{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ ];

  boot.initrd.availableKernelModules = [ "ata_piix" "mptspi" "uhci_hcd" "ehci_pci" "ahci" "nvme" "xhci_pci" "sr_mod" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "size=512M" "mode=755" ];
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/3f8afa8c-f060-48a7-9f98-944512f87db3";
      fsType = "btrfs";
      options = [ "noatime" "compress=zstd" "subvol=@nix" "discard" ];
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/3f8afa8c-f060-48a7-9f98-944512f87db3";
      fsType = "btrfs";
      options = [ "noatime" "compress=zstd" "subvol=@home" "discard" ];
    };

  fileSystems."/persist" =
    {
      device = "/dev/disk/by-uuid/3f8afa8c-f060-48a7-9f98-944512f87db3";
      fsType = "btrfs";
      options = [ "noatime" "compress=zstd" "subvol=@persist" "discard" ];
      neededForBoot = true;
    };

  fileSystems."/tmp" =
    {
      device = "none";
      fsType = "tmpfs";
      options = [ "defaults" "mode=1755" ];
      neededForBoot = true;
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/CBF5-04B4";
      fsType = "vfat";
    };

  fileSystems."/var/log" =
    {
      device = "/persist/var/log";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/var/lib/docker" =
    {
      device = "/persist/var/lib/docker";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/etc/nixos" =
    {
      device = "/persist/etc/nixos";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/etc/ssh" =
    {
      device = "/persist/etc/ssh";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/veryhugepages" =
    {
      device = "none";
      fsType = "hugetlbfs";
      options = [ "pagesize=1G" ];
    };

  # VMWare specific
  #fileSystems."/mnt/host" =
  #  { device = ".host:/";
  #    fsType = "fuse.vmhgfs-fuse";
  #    options = [ "defaults" "allow_other" ];
  #  };


  swapDevices = [ ];

}
