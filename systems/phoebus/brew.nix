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
    autoUpdate = false;
    brewPrefix = "/opt/homebrew/bin";
    brews = lib.optionals stdenv.isAarch64 [
      # depends on pyopenssl, which is broken
      "ansible"
      "azure-cli"
      "yq"
    ];
  };
}
