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

  outputs = { self, darwin, nixpkgs, nixpkgs-master, home-manager, impermanence }: rec {
      nixosModules.nixpkgsCommon = { stdenv, ... }: {
        nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
        nix.registry.nixpkgs.flake = nixpkgs;
        home-manager.useGlobalPkgs = true;

        nixpkgs.config = {
          allowUnfree = true;
        };
      };

      darwinModules.nixpkgsCommon = nixosModules.nixpkgsCommon;

      darwinConfigurations."miniskeem" =
        let
          useRosetta = true;

          intelPkgs = if (useRosetta) then nixpkgs.legacyPackages."x86_64-darwin" else null;
        in
        darwin.lib.darwinSystem rec {
          system = "aarch64-darwin";
          modules = [
            darwinModules.nixpkgsCommon
            home-manager.darwinModules.home-manager
            (args@{ config, pkgs, lib, stdenv, ... }: (import ./systems/miniskeem (args // { inherit useRosetta intelPkgs; })))
          ];
        };

      nixosConfigurations."meeksorkim2" = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          nixosModules.nixpkgsCommon
          ./systems/meeksorkim2
          (import ./systems/_linux/docker.nix { })
        ];
      };
    };
}
