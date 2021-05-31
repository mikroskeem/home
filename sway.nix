{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    # gui
    gtk-engine-murrine
    gtk_engines
    gsettings-desktop-schemas
    polkit_gnome
  ];

  environment.pathsToLink = [ "/libexec" ]; # https://nixos.wiki/wiki/Sway#Polkit

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
    extraPortals = [ pkgs.xdg-desktop-portal-wlr ];
  };

  systemd.user.services.xdg-desktop-portal-wlr = {
    # XXX: not sure why this is not being done yet?
    path = with pkgs; [ wofi slurp ];
  };

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
    media-session.enable = true;
  };

  security.rtkit.enable = true;
}
