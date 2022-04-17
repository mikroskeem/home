{ config, lib, pkgs, ... }:

{
  programs.steam.enable = true;
  programs.steam.remotePlay.openFirewall = true;
  services.pipewire.alsa.support32Bit = config.services.pipewire.enable;
  environment.systemPackages = with pkgs; [
    mangohud
    alsaUtils
  ];

  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "mark";
}
