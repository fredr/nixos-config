{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-24.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur.url = "github:nix-community/NUR";

    nix-colors.url = "github:misterio77/nix-colors";

    encore.url = "github:encoredev/encore-flake";
  };


  outputs = { nixpkgs, nur, home-manager, encore, ... }@inputs:
    let
      system = "x86_64-linux";
      home-manager-conf = { host, ... }: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        home-manager.extraSpecialArgs = { inherit inputs host; };
        home-manager.users.fredr = import ./home-manager;
      };
      unstable-packages = final: _prev: {
        unstable = import inputs.nixpkgs-unstable {
          system = final.system;
          config.allowUnfree = true;
        };
      };

      encore-overlay = final: _prev: {
        encore = encore.packages.${final.system}.encore;
      };

      mypkgs = final: _prev: {
        mypkgs = import ./pkgs {
          pkgs = final.pkgs;
        };
      };

      overlays = {
        nixpkgs.overlays = [
          nur.overlay
          unstable-packages
          mypkgs
        ];
      };
    in
    {
      nixosConfigurations.flatnix =
        let
          host = {
            hostname = "flatnix";
            pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpKQ7mHkk7LXzlV95YahAg76K6llq2QFAKVqiiSMoHm";
          };
        in
        nixpkgs.lib.nixosSystem {
          system = system;

          specialArgs = { inherit inputs host; };

          modules = [
            ./modules/configuration.nix
            ./hosts/flatnix
            home-manager.nixosModules.home-manager
            home-manager-conf
            overlays
          ];
        };


      nixosConfigurations.slimnix =
        let
          host = {
            hostname = "slimnix";
            pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJypu216HqvuovQMbSesFBOOp+NEA/egmhS32pE7CRjw";
          };
        in
        nixpkgs.lib.nixosSystem {
          system = system;

          specialArgs = { inherit inputs host; };

          modules = [
            ./modules/configuration.nix
            ./hosts/slimnix
            home-manager.nixosModules.home-manager
            home-manager-conf
            overlays
          ];
        };

      devShells."${system}" = {
        encore-rel =
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ encore-overlay ];
            };
          in
          pkgs.mkShellNoCC {
            packages = [ pkgs.encore ];

            shellHook = ''
              export SHELL_NAME=''${SHELL_NAME}''${SHELL_NAME:+>}encore-rel
            '';
          };

        encore-dev =
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ mypkgs ];
            };

            encoreDev = "/home/fredr/projects/encoredev";
            gobin = "/home/fredr/go/bin";
            cargobin = "/home/fredr/.cargo/bin";
          in
          pkgs.mkShellNoCC {
            packages = [ pkgs.mypkgs.stringer ];

            shellHook = ''
              export SHELL_NAME=''${SHELL_NAME}''${SHELL_NAME:+>}encore-dev

              export ENCORE_RUNTIMES_PATH=${encoreDev}/encore/runtimes
              export ENCORE_GOROOT=${encoreDev}/go/dist/linux_amd64/encore-go
              export ENCORE_TSPARSER_PATH=${cargobin}/tsparser-encore
              export ENCORE_TSBUNDLER_PATH=${gobin}/tsbundler-encore
            '';
          };
      };
    };
}

