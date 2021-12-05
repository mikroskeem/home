{ config, lib, pkgs, modulesPath, ... }:

{
  imports =
    [
      (modulesPath + "/installer/scan/not-detected.nix")
    ];

  boot.initrd.availableKernelModules = [ "xhci_pci" "ehci_pci" "ahci" "usb_storage" "sd_mod" "sr_mod" "rtsx_pci_sdmmc" ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [ "kvm-intel" ];
  boot.extraModulePackages = [ ];

  fileSystems."/" =
    {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" "size=512M" "mode=755" ];
    };

  fileSystems."/tmp" =
    {
      device = "tmpfs";
      fsType = "tmpfs";
      options = [ "defaults" "size=6G" "mode=1755" ];
    };

  fileSystems."/var/tmp" =
    {
      device = "/tmp";
      fsType = "none";
      options = [ "bind" ];
    };

  fileSystems."/persist" =
    {
      device = "/dev/disk/by-uuid/891a6ff1-9a75-4817-96c0-dd1eaacaba70";
      fsType = "btrfs";
      options = [ "noatime" "subvol=@persist" ];
      neededForBoot = true;
    };

  fileSystems."/home" =
    {
      device = "/dev/disk/by-uuid/891a6ff1-9a75-4817-96c0-dd1eaacaba70";
      fsType = "btrfs";
      options = [ "noatime" "subvol=@home" "user_subvol_rm_allowed" ];
      neededForBoot = true;
    };

  fileSystems."/nix" =
    {
      device = "/dev/disk/by-uuid/891a6ff1-9a75-4817-96c0-dd1eaacaba70";
      fsType = "btrfs";
      options = [ "noatime" "subvol=@nix" ];
      neededForBoot = true;
    };

  fileSystems."/private" =
    {
      device = "/dev/disk/by-uuid/891a6ff1-9a75-4817-96c0-dd1eaacaba70";
      fsType = "btrfs";
      options = [ "noatime" "subvol=@private" ];
      neededForBoot = true;
    };

  fileSystems."/boot" =
    {
      device = "/dev/disk/by-uuid/5E5C-04BA";
      fsType = "vfat";
      options = [ "defaults" ];
    };

  swapDevices =
    [{ device = "/dev/disk/by-uuid/6e3435da-071b-4f66-9ee8-20b6eea42865"; }];

  powerManagement.cpuFreqGovernor = lib.mkDefault "performance";
}
