{ config, lib, pkgs, ... }: {
  users.mutableUsers = false;

  # yes yes don't care.
  users.users.root.initialHashedPassword = "$6$g5eYGL/1LqgmsrI9$QjeXt6hTibVPNWRNd3CmxjiD4hSRplQEgjUSpQLxScGWQ340Zz0UrE8CgEHSZ5GjCIW3AjRp/LKxi78TGkDvZ1";
  users.users.mark = {
    initialHashedPassword = "$6$uUuCGRcjqBQI6ylj$pJ9erlvHOVTt9gaJHeT21LBIXia3tt0lTBRbSoApvfwldCDKJpHKH2o7zt9lKWAW20bQs0yijSqxNAb/FBToI0";
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
