{ config, lib, pkgs, ... }:
{
  vendoredConfig.hasDesktop = true;

  environment.systemPackages = with pkgs; [
    # gui
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    polkit_gnome

    # audio
    pavucontrol
  ];

  # https://nixos.wiki/wiki/Sway#Polkit
  environment.pathsToLink = [ "/libexec" ];

  fonts.enableDefaultFonts = true;
  fonts.fontconfig.enable = true;
  programs.dconf.enable = true; # for setting GTK themes to work properly

  boot.plymouth.enable = true;
  boot.plymouth.theme = "breeze"; # https://github.com/NixOS/nixpkgs/blob/nixos-21.11/nixos/modules/system/boot/plymouth.nix

  services.gnome.gnome-keyring.enable = true;
  services.xserver.enable = true;
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.displayManager.gdm.wayland = true;
  services.xserver.desktopManager.gnome.enable = true;

  environment.gnome.excludePackages = [ pkgs.gnome.cheese pkgs.gnome-photos pkgs.gnome.gnome-music pkgs.gnome.gnome-terminal pkgs.gnome.gedit pkgs.epiphany pkgs.evince pkgs.gnome.gnome-characters pkgs.gnome.totem pkgs.gnome.tali pkgs.gnome.iagno pkgs.gnome.hitori pkgs.gnome.atomix pkgs.gnome-tour ];

  xdg.portal = {
    enable = true;
    gtkUsePortal = true;
  };

  # gnome really wants to use networkmanager, so let's try to tame it a little bit
  networking.networkmanager.wifi.backend = "iwd";
  networking.networkmanager.firewallBackend = "nftables";

  hardware.pulseaudio.enable = false;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  security.rtkit.enable = true;

  security.pam.loginLimits = lib.optionals config.services.pipewire.enable [
    {
      domain = "@users";
      item = "memlock";
      type = "soft";
      value = "64";
    }
    {
      domain = "@users";
      item = "memlock";
      type = "hard";
      value = "128";
    }
  ];
}
