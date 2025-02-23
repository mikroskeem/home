{ config, pkgs, ... }:

{
  nix.enable = true;
  nix.package = pkgs.nixVersions.stable;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';
}
