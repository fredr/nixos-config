{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixos-23.11;

    home-manager = {
      url = github:nix-community/home-manager/release-23.11;
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = github:nix-community/NUR;

    nix-colors.url = github:misterio77/nix-colors;

    fenix = {
      url = github:nix-community/fenix;
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { nixpkgs, nur, fenix, home-manager, ... }@inputs:
  let
    pkgs = import nixpkgs {
      overlays = [
	nur.overlays
	fenix.overlays.default
      ];
    };
  in
  {
    packages.x86_64-linux.default = fenix.packages.x86_64-linux.minimal.toolchain;
    nixosConfigurations.slimnix = let
	host = {
            hostname = "slimnix";
            pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJypu216HqvuovQMbSesFBOOp+NEA/egmhS32pE7CRjw";
	};
    in nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";

      specialArgs = { inherit inputs host; };

      modules = [
        ./modules/configuration.nix
	./hosts/slimnix
	nur.nixosModules.nur
	home-manager.nixosModules.home-manager
	{
          home-manager.useGlobalPkgs = true;
	  home-manager.useUserPackages = true;

	  home-manager.extraSpecialArgs = { inherit inputs host; };

	  home-manager.users.fredr = import ./home-manager/home.nix;

	  nixpkgs.overlays = [
            nur.overlay
	    fenix.overlays.default
	  ];
	}
      ];
    };
  };
}
