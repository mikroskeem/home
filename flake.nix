{
  description = "miniskeem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    darwin.url = "github:lnl7/nix-darwin/master";
    home-manager.url = "github:nix-community/home-manager/master";

    darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs, home-manager }:
    let
      nixpkgsConfig = {
        config = {
          allowUnfree = true;
        };
      };
    in
    {
      # TODO: hostname is "miniskeem.lan" :(
      darwinConfigurations."miniskeem"."lan" =
        let
          useRosetta = true;

          intelPkgs = if (useRosetta) then (import nixpkgs (nixpkgsConfig // { system = "x86_64-darwin"; })) else null;
        in
        darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          modules = [
            home-manager.darwinModules.home-manager
            ({ ... }: {
              nixpkgs.config.allowUnfree = true;

              nixpkgs.overlays = [
                # https://github.com/NixOS/nixpkgs/issues/138157
                (final: prev: {
                  nixUnstable = prev.nixUnstable.overrideAttrs (old: {
                    patches = old.patches ++ [ ./patches/nix/unset-is-macho.patch ];
                    meta = (old.meta or { }) // {
                      priority = 10;
                    };
                  });
                })
              ];

              home-manager.useGlobalPkgs = true;
            })
            (args@{ config, pkgs, lib, stdenv, ... }: (import ./systems/miniskeem.nix (args // { inherit useRosetta intelPkgs; })))
          ];
        };
    };
}
