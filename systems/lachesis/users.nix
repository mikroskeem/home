{ config, lib, pkgs, ... }: {
  users.mutableUsers = false;

  users.users.root = { };

  users.users.mark = {
    isNormalUser = true;

    shell = pkgs.zsh;
    extraGroups = [ "wheel" ]
      ++ lib.optional config.virtualisation.docker.enable "docker";
  };

  home-manager.users.mark = { pkgs, ... }@args: (import ../../home/mark.nix (args // {
    hasDesktop = config.vendoredConfig.hasDesktop;
    intelPkgs = null;
  }));
}
