{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix-colors.url = "github:misterio77/nix-colors";

    encore = {
      url = "github:encoredev/encore-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          nur.overlays.default
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

            # protoc 4.23.4
            protobuf-pkgs = import
              (pkgs.fetchFromGitHub {
                owner = "NixOS";
                repo = "nixpkgs";
                rev = "05bbf675397d5366259409139039af8077d695ce";
                sha256 = "IE7PZn9bSjxI4/MugjAEx49oPoxu0uKXdfC+X7HcRuQ=";
              })
              {
                inherit system;
              };

            # protoc-gen-go 1.31.0 & protoc-gen-go-grpc 1.3.0
            proto-gen-pkgs = import
              (pkgs.fetchFromGitHub {
                owner = "NixOS";
                repo = "nixpkgs";
                rev = "f194412e36bff594767b95c4bd023c653a4cae41";
                sha256 = "L/xaRcjRTxte5cZw6ofJxfN8yBZakk1rijqp58plK1w=";
              })
              {
                inherit system;
              };

            # sqlc 1.25.0
            sqlc-pkgs = import
              (pkgs.fetchFromGitHub {
                owner = "NixOS";
                repo = "nixpkgs";
                rev = "b0dc996a606919d2762e427296c902ca476b6470";
                sha256 = "sha256-T6Y4/Bp1HN84uCXZ56dQ0Wwr8rWjgIvjdENRMcmRk1I=";
              })
              {
                inherit system;
              };

            sqlc = sqlc-pkgs.sqlc;

            protobuf = protobuf-pkgs.protobuf_23;
            protoc-gen-go = proto-gen-pkgs.protoc-gen-go;
            protoc-gen-go-grpc = proto-gen-pkgs.protoc-gen-go-grpc;

            encoreDev = "/home/fredr/projects/encoredev";
            gobin = "/home/fredr/go/bin";
            cargobin = "/home/fredr/.cargo/bin";

            buildCommand = pkgs.writeShellScriptBin "encore-build-all" ''
              #!${pkgs.bash}/bin/bash
              (
                cd ${encoreDev}/encore/ &&
                cargo install --path tsparser --debug &&
                go install ./cli/cmd/tsbundler-encore &&
                go run ./pkg/encorebuild/cmd/build-local-binary all --builder cargo &&
                go install ./cli/cmd/encore &&
                encore daemon
              )
            '';
          in
          pkgs.mkShellNoCC {
            buildInputs = with pkgs; [
              llvmPackages.clang
            ];
            packages = [
              pkgs.mypkgs.stringer
              buildCommand
              protobuf
              protoc-gen-go
              protoc-gen-go-grpc
              pkgs.semgrep
              sqlc
              pkgs.mypkgs.goimports
            ];

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
