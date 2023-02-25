{ config
, lib
, pkgs
, ...
}:

let
  # nix-darwin does not export stdenv?
  inherit (pkgs) stdenv;
in
{
  homebrew = lib.optionalAttrs stdenv.isDarwin {
    enable = true;
    onActivation.autoUpdate = false;
    brewPrefix = "/opt/homebrew/bin";
    brews = lib.optionals stdenv.isAarch64 [
      "ncdu"
    ];
  };
}
