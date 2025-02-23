{ config
, pkgs
, lib
, intelPkgs
, useRosetta
, hasDesktop
, ...
}:

{
  imports = [
    ../_common/nix.nix
    ./brew.nix
  ];

  system.stateVersion = 4;

  programs.zsh.enable = true;
  programs.bash.enable = true;

  nix.settings = {
    trusted-users = [ "root" "@admin" ];
    sandbox = false; # TODO: giga slow
    extra-sandbox-paths = lib.optionals (useRosetta && config.nix.settings.sandbox) [
      "/private/var/db/oah"
      "/Library/Apple"
    ];
  };

  nix.extraOptions = lib.optionalString useRosetta ''
    extra-platforms = x86_64-darwin
  '';

  networking.hostName = "phoebus";

  users.users.mark = {
    name = "mark";
    home = "/Users/mark";
  };

  fonts = {
    fontDir.enable = false; # https://github.com/LnL7/nix-darwin/issues/485
    fonts = with pkgs; [ hack-font emacs-all-the-icons-fonts ];
  };

  environment.systemPackages = with pkgs; [ ];

  system.build.applications = lib.mkForce (pkgs.buildEnv {
    name = "applications";
    paths = config.environment.systemPackages
      ++ lib.flatten (map (user: user.home.packages or [ ]) (lib.attrValues config.home-manager.users));
    pathsToLink = "/Applications";
  });

  security.pam.enableSudoTouchIdAuth = true;

  home-manager.users.mark = import ../../home/mark.nix;
  home-manager.extraSpecialArgs = {
    inherit intelPkgs hasDesktop;
  };

  system.activationScripts.postActivation.text = ''
    mkdir -p -m 0755 /usr/local/lib/pam
    ln -svf ${pkgs.yubico-pam}/lib/security/pam_yubico.so /usr/local/lib/pam/pam_yubico.so
    ${pkgs.gnused}/bin/sed -i '2iauth sufficient pam_yubico.so mode=challenge-response # mikroskeem/home' /etc/pam.d/sudo
  '';
}
