{
  description = "miniskeem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    darwin.url = "github:lnl7/nix-darwin/master";
    flake-utils.url = "github:numtide/flake-utils";
    home-manager.url = "github:nix-community/home-manager/master";
    impermanence.url = "github:nix-community/impermanence/master";
    nixos-generators.url = "github:nix-community/nixos-generators";
    agenix.url = "github:ryantm/agenix";
    sops.url = "github:Mic92/sops-nix";

    impure-local.url = "path:/etc/nixos";
    impure-local.flake = false;

    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
    sops.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, darwin, flake-utils, home-manager, impermanence, impure-local, ... }@inputs:
    let
      supportedSystems = [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      nixosModules.nixpkgsCommon = { ... }: {
        nix.nixPath = [ "nixpkgs=${nixpkgs.outPath}" ];
        nix.registry.nixpkgs.flake = nixpkgs;
        home-manager.useGlobalPkgs = true;

        nixpkgs.config = {
          allowUnfree = true;
        };
      };

      darwinModules.nixpkgsCommon = self.nixosModules.nixpkgsCommon;

      nixosModules.impermanenceConfig = import ./modules/impermanence.nix;

      darwinConfigurations."miniskeem" = darwin.lib.darwinSystem {
        system = "aarch64-darwin";
        modules = [
          self.darwinModules.nixpkgsCommon
          home-manager.darwinModules.home-manager
          ./systems/miniskeem
          "${impure-local}"
        ];
        specialArgs = rec {
          hasDesktop = true;
          useRosetta = true;
          intelPkgs = if (useRosetta) then nixpkgs.legacyPackages."x86_64-darwin" else null;
        };
      };

      nixosConfigurations."meeksorkim2" = nixpkgs.lib.nixosSystem rec {
        system = "x86_64-linux";
        modules = [
          self.nixosModules.nixpkgsCommon
          self.nixosModules.impermanenceConfig
          inputs.agenix.nixosModules.age
          inputs.sops.nixosModules.sops
          home-manager.nixosModules.home-manager
          impermanence.nixosModules.impermanence
          ./systems/meeksorkim2
          "${impure-local}"
        ];
      };

      packages.x86_64-linux.kexecBootstrap =
        inputs.nixos-generators.nixosGenerate {
          pkgs = nixpkgs.legacyPackages."x86_64-linux";
          format = "kexec-bundle";
          modules = [
            ./systems/_common/nix.nix
          ];
        };
    } // flake-utils.lib.eachSystem supportedSystems (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell =
          pkgs.mkShell {
            nativeBuildInputs = [
              pkgs.sops
              pkgs.rage
              pkgs.ssh-to-age
              inputs.agenix.defaultPackage.${system}
            ];
          };
      });
}
