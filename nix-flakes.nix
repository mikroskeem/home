{ pkgs, ... }: {
  environment.systemPackages = [
    (pkgs.writeScriptBin "nixf" ''
      #!${pkgs.bash}/bin/bash
      exec ${pkgs.nixUnstable}/bin/nix --experimental-features "nix-command flakes" "$@"
    '')
  ];
}
