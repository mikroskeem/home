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

    # video
    wdisplays
  ];

  # https://nixos.wiki/wiki/Sway#Polkit
  environment.pathsToLink = [ "/libexec" ];

  fonts.enableDefaultFonts = true;
  fonts.fontconfig.enable = true;
  programs.dconf.enable = true; # for setting GTK themes to work properly

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
    wlr.enable = true;
    #extraPortals = [ pkgs.xdg-desktop-portal-wlr ]; # TODO: https://github.com/NixOS/nixpkgs/issues/91218
  };

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
