{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
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

    # Pinned nixpkgs for specific tool versions
    nixpkgs-protobuf.url = "github:NixOS/nixpkgs/e2daad4d9da87f6a838e76ce65040b1ffabb1993"; # protoc 6.32.1
    nixpkgs-protoc-gen.url = "github:NixOS/nixpkgs/0c84e29495353f736f4715ee13f0f25e5ba602e6"; # protoc-gen-go 1.36.10 & protoc-gen-go-grpc 1.5.1
    nixpkgs-sqlc.url = "github:NixOS/nixpkgs/b0dc996a606919d2762e427296c902ca476b6470"; # sqlc 1.25.0
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

      # Pre-import pinned nixpkgs versions to reuse across shells
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ mypkgs ];
      };

      # Import pinned nixpkgs from inputs for specific tool versions
      protobuf-pkgs = import inputs.nixpkgs-protobuf { inherit system; };
      proto-gen-pkgs = import inputs.nixpkgs-protoc-gen { inherit system; };
      sqlc-pkgs = import inputs.nixpkgs-sqlc { inherit system; };
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
            encore-pkgs = import nixpkgs {
              inherit system;
              overlays = [ encore-overlay ];
            };
          in
          encore-pkgs.mkShellNoCC {
            packages = [ encore-pkgs.encore ];

            shellHook = ''
              export SHELL_NAME=''${SHELL_NAME}''${SHELL_NAME:+>}encore-rel
            '';
          };

        encore-dev =
          let
            sqlc = sqlc-pkgs.sqlc;
            protobuf = protobuf-pkgs.protobuf_32;
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
