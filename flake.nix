{
  description = "miniskeem";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    nixpkgs-master.url = "github:nixos/nixpkgs/master";
    darwin.url = "github:lnl7/nix-darwin/master";
    home-manager.url = "github:nix-community/home-manager/master";
    impermanence.url = "github:nix-community/impermanence/master";
    nixos-generators.url = "github:nix-community/nixos-generators";
    agenix.url = "github:ryantm/agenix";

    darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    nixos-generators.inputs.nixpkgs.follows = "nixpkgs";
    agenix.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, darwin, nixpkgs, home-manager, impermanence, ... }@inputs: {
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
      ];
      specialArgs = rec {
        hasDesktop = true;
        useRosetta = true;
        intelPkgs = if (useRosetta) then nixpkgs.legacyPackages."x86_64-darwin" else null;
      };
    };

    nixosConfigurations."meeksorkim2" = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        self.nixosModules.nixpkgsCommon
        self.nixosModules.impermanenceConfig
        inputs.agenix.nixosModules.age
        home-manager.nixosModules.home-manager
        impermanence.nixosModules.impermanence
        ./systems/meeksorkim2
      ];
    };

    packages.x86_64-linux.kexecBootstrap = let
      system = "x86_64-linux";
    in inputs.nixos-generators.nixosGenerate {
      pkgs = nixpkgs.legacyPackages.${system};
      format = "kexec_bundle";
      modules = [
        ./systems/_common/nix.nix
      ];
    };
  };
}
