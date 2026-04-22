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
          system = final.stdenv.hostPlatform.system;
          config.allowUnfree = true;
        };
      };

      encore-overlay = final: _prev: {
        encore = encore.packages.${final.stdenv.hostPlatform.system}.encore;
      };

      # https://github.com/NixOS/nixpkgs/issues/505078
      obsidian-fix = final: prev: {
        obsidian = prev.obsidian.overrideAttrs (old: {
          nativeBuildInputs = old.nativeBuildInputs ++ [ final.asar final.jq ];
          postPatch = (old.postPatch or "") + ''
            mkdir _app
            asar extract ./resources/app.asar ./_app
            jq '.desktopName = "obsidian"' ./_app/package.json > ./_app/package.json.tmp
            mv ./_app/package.json.tmp ./_app/package.json
            asar pack ./_app ./resources/app.asar
            rm -r _app
          '';
        });
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
          obsidian-fix
          mypkgs
        ];
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ mypkgs ];
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
          specialArgs = { inherit inputs host; };

          modules = [
            { nixpkgs.hostPlatform = system; }
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
          specialArgs = { inherit inputs host; };

          modules = [
            { nixpkgs.hostPlatform = system; }
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
              export SHELL_NAME="''${SHELL_NAME}''${SHELL_NAME:+>}encore-rel"
            '';
          };

        encore-dev =
          let
            # Use encore-specific versions downloaded as pre-built binaries
            sqlc = pkgs.mypkgs.sqlc-encore;
            protobuf = pkgs.mypkgs.protoc-encore;
            protoc-gen-go = pkgs.mypkgs.protoc-gen-go-encore;
            protoc-gen-go-grpc = pkgs.mypkgs.protoc-gen-go-grpc-encore;

            encoreDev = "/home/fredr/projects/encoredev";

            buildCommand = pkgs.writeShellScriptBin "encore-build-all" ''
              #!${pkgs.bash}/bin/bash
              src_dir="''${ENCORE_WORKTREE_DIR:-${encoreDev}/encore}"
              (
                cd "$src_dir" &&
                cargo install --path tsparser --debug &&
                go install ./cli/cmd/tsbundler-encore &&
                go install ./cli/cmd/git-remote-encore &&
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
              _encore_base="''${ENCORE_WORKTREE_DIR:-${encoreDev}/encore}"
              _encore_bin="$_encore_base/.encore/bin"
              mkdir -p "$_encore_bin"

              export GOBIN="$_encore_bin"
              export CARGO_INSTALL_ROOT="$_encore_base/.encore"
              export ENCORE_RUNTIMES_PATH="$_encore_base/runtimes"
              export ENCORE_GOROOT=${encoreDev}/go/dist/linux_amd64/encore-go
              export ENCORE_TSPARSER_PATH="$_encore_bin/tsparser-encore"
              export ENCORE_TSBUNDLER_PATH="$_encore_bin/tsbundler-encore"
              export PATH="$_encore_bin:$PATH"

              if [ -n "''${ENCORE_WORKTREE_NAME:-}" ]; then
                export SHELL_NAME="encore-dev($ENCORE_WORKTREE_NAME)"
                if [ "''${ENCORE_WORKTREE_NEW:-0}" = "1" ]; then
                  cd "$ENCORE_WORKTREE_DIR"
                fi
              else
                export SHELL_NAME="''${SHELL_NAME}''${SHELL_NAME:+>}encore-dev"
              fi

              unset _encore_base _encore_bin
            '';
          };
      };
    };
}
