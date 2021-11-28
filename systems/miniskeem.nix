{ config
, pkgs
, lib
, intelPkgs
, useRosetta ? false
, ...
}:

{
  services.nix-daemon.enable = true;
  programs.zsh.enable = true;
  programs.bash.enable = true;

  nix.package = pkgs.nixUnstable;
  nix.useSandbox = false; # TODO: giga slow

  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '' + lib.optionalString useRosetta ''
    extra-platforms = x86_64-darwin
  '';

  nix.sandboxPaths = lib.optionals (useRosetta && config.nix.useSandbox) [
    "/private/var/db/oah"
    "/Library/Apple"
  ];

  users.users.mark = {
    home = "/Users/mark";
  };

  fonts = {
    enableFontDir = true;
    fonts = with pkgs; [ hack-font emacs-all-the-icons-fonts ];
  };

  environment.systemPackages = with pkgs; [ ];

  system.build.applications = lib.mkForce (pkgs.buildEnv {
    name = "applications";
    paths = config.environment.systemPackages
      ++ lib.flatten (map (user: user.home.packages or [ ]) (lib.attrValues config.home-manager.users));
    pathsToLink = "/Applications";
  });

  home-manager.users.mark = { pkgs, ... }@args: (import ../home/mark.nix (args // { inherit intelPkgs; }));

  system.stateVersion = 4;
}
