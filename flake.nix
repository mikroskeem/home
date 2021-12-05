{
  description = "miniskeem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    darwin.url = "github:lnl7/nix-darwin/master";
    home-manager.url = "github:nix-community/home-manager/master";
    impermanence.url = "github:nix-community/impermanence/master";

    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs, nixpkgs-master, home-manager, impermanence }:
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

                # https://github.com/NixOS/nixpkgs/pull/148251 not on nixpkgs-unstable yet
                (final: prev: {
                  qemu = nixpkgs-master.legacyPackages.${system}.qemu;
                })
              ];

              home-manager.useGlobalPkgs = true;
            })
            (args@{ config, pkgs, lib, stdenv, ... }: (import ./systems/miniskeem (args // { inherit useRosetta intelPkgs; })))
          ];
        };

      nixosConfigurations."meeksorkim2" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          ({ ... }: {
            nixpkgs.config.allowUnfree = true;
            home-manager.useGlobalPkgs = true;
          })
          ./systems/meeksorkim2
          (import ./systems/_linux/docker.nix { })
        ];
      };
    };
}
