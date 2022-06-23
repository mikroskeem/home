{ config, lib, pkgs, ... }: {
  users.mutableUsers = false;

  users.users.root = { };

  users.users.mark = {
    isNormalUser = true;

    shell = pkgs.zsh;
    extraGroups = [ "wheel" ]
      ++ lib.optional config.virtualisation.docker.enable "docker";
  };

  home-manager.users.mark = import ../../home/mark.nix;
  home-manager.extraSpecialArgs = {
    inherit (config.vendoredConfig) hasDesktop;
    intelPkgs = null;
  };
}
