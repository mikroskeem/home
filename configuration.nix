{ config, pkgs, lib, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      (import "${builtins.fetchTarball "https://github.com/rycee/home-manager/archive/master.tar.gz"}/nixos")
      ./users.nix
      ./tmpfs-root.nix
      ./nix-flakes.nix
      #./lxc.nix
      #./sway.nix

      ./vmware-guest.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];

  networking.useDHCP = false;
  networking.interfaces.ens33.useDHCP = true;
  networking.hostName = "nixos";
  networking.hostId = "007f0200";
  networking.firewall.enable = false;

  time.timeZone = "Europe/Tallinn";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  environment.systemPackages = with pkgs; [
    neovim-unwrapped
    htop ncdu strace lsof exa curl
  ];

  users.users.mark = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.pathsToLink = [ "/share/zsh" ];

  environment.variables = {
    "EDITOR" = "nvim";
    "VISUAL" = "nvim";
  };

  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 512; # 128 * 4
    "fs.inotify.max_user_watches" = 32768; # 8192 * 4
  };

  services.openssh.enable = true;

  nixpkgs.overlays = [
    (import (builtins.fetchTarball {
      url = https://github.com/nix-community/emacs-overlay/archive/master.tar.gz;
    }))
  ];

  nixpkgs.config.allowUnfree = true;

  nix = {
    binaryCaches = [
      "https://t2linux.cachix.org"
      "https://nix-community.cachix.org"
    ];
    binaryCachePublicKeys = [
      "t2linux.cachix.org-1:P733c5Gt1qTcxsm+Bae0renWnT8OLs0u9+yfaK2Bejw="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  system.stateVersion = "21.05";
}

