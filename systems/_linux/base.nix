{ config, lib, pkgs, ... }:

{
  imports = [
    ./helper.nix
  ];

  i18n.defaultLocale = "en_US.UTF-8";
  console = {
    font = "Lat2-Terminus16";
    keyMap = "us";
  };

  services.openssh.enable = true;
  services.openssh.extraConfig = ''
    # https://wiki.gnupg.org/AgentForwarding
    StreamLocalBindUnlink yes
  '';

  security.sudo.extraConfig = ''
    Defaults lecture="never"
  '';

  boot.kernel.sysctl = {
    # bump inotify stuff for IntelliJ-based IDEs
    "fs.inotify.max_user_instances" = 512; # 128 * 4
    "fs.inotify.max_user_watches" = 32768; # 8192 * 4
  };

  boot.kernelParams = [
    "loop.max_part=8"
  ];

  programs.zsh.enable = true;
}
