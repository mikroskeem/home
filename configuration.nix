{ config, pkgs, lib, ... }:

{
  imports =
    [ ./hardware-configuration.nix
      (import "${builtins.fetchTarball "https://github.com/rycee/home-manager/archive/master.tar.gz"}/nixos")
      ./users.nix
      ./tmpfs-root.nix
      ./nix-flakes.nix

      # TODO(2021-05-13) - open-vm-tools does not build
      ./vmware-guest-tools-fix.nix
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.supportedFilesystems = [ "zfs" ];

  networking.useDHCP = false;
  networking.interfaces.ens33.useDHCP = true;
  networking.hostName = "nixos";
  networking.hostId = "007f0200";

  time.timeZone = "Europe/Tallinn";
  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  users.users.mark = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  networking.firewall.enable = false;

  environment.systemPackages = with pkgs; [
    neovim-unwrapped
    htop ncdu strace lsof exa curl

    # gui
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    polkit_gnome
  ];

  environment.pathsToLink = [ "/share/zsh" ] ++
  [ "/libexec" ]; # https://nixos.wiki/wiki/Sway#Polkit

  environment.variables = {
    "EDITOR" = "nvim";
    "VISUAL" = "nvim";

  } // lib.optionalAttrs (config.virtualisation.vmware.guest.enable) {
    "WLR_NO_HARDWARE_CURSORS" = "1";
  };

  boot.kernel.sysctl = {
    "fs.inotify.max_user_instances" = 512; # 128 * 4
    "fs.inotify.max_user_watches" = 32768; # 8192 * 4
  };

  fonts.enableDefaultFonts = true;
  fonts.fontconfig.enable = true;

  programs.sway = {
    enable = true;
    wrapperFeatures.gtk = true;
    extraPackages = with pkgs; [
      wofi
      wl-clipboard
      mako
      alacritty
      xwayland
      i3status
    ];

    extraSessionCommands = ''
      export SDL_VIDEODRIVER=wayland
      export QT_QPA_PLATFORM=wayland
      export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
      export _JAVA_AWT_WM_NONREPARENTING=1
      export XDG_CURRENT_DESKTOP=sway
    '';
  };

  # https://elis.nu/blog/2021/02/detailed-setup-of-screen-sharing-in-sway
  xdg.portal = {
    enable = true;
    gtkUsePortal = true;
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  systemd.user.services.xdg-desktop-portal-wlr = {
    # XXX: not sure why this is not being done yet?
    path = with pkgs; [ wofi slurp ];
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    media-session.enable = true;
  };

  programs.dconf.enable = true; # for setting GTK themes to work properly

  services.openssh.enable = true;
  virtualisation.vmware.guest.enable = true;

  system.stateVersion = "21.05";

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
}

