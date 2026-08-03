{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
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

  outputs =
    {
      nixpkgs,
      nur,
      home-manager,
      encore,
      ...
    }@inputs:
    let
      system = "x86_64-linux";
      home-manager-conf = { host, ... }: {
        home-manager.useGlobalPkgs = true;
        home-manager.useUserPackages = true;
        # Move a colliding file aside instead of failing activation
        home-manager.backupFileExtension = "hm-bak";
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
          nativeBuildInputs = old.nativeBuildInputs ++ [
            final.asar
            final.jq
          ];
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

      # On Linux, nixpkgs builds electron_40/41/42 from source (Chromium), which
      # Hydra often hasn't cached yet, forcing slow local compiles. Use the
      # cached upstream prebuilt binaries instead.
      electron-bin-fix = final: prev: {
        electron_40 = prev.electron_40-bin;
        electron_41 = prev.electron_41-bin;
      };

      overlays = {
        nixpkgs.overlays = [
          nur.overlays.default
          unstable-packages
          obsidian-fix
          electron-bin-fix
          mypkgs
        ];
      };

      pkgs = import nixpkgs {
        inherit system;
        overlays = [ mypkgs ];
      };

      # A host is its hostname plus the ssh key it signs commits with.
      # ./hosts/<hostname> picks which of the ./modules/* roles it wants.
      mkHost =
        { hostname, pubKey }:
        nixpkgs.lib.nixosSystem {
          specialArgs = {
            inherit inputs;
            host = { inherit hostname pubKey; };
          };

          modules = [
            { nixpkgs.hostPlatform = system; }
            ./hosts/${hostname}
            home-manager.nixosModules.home-manager
            home-manager-conf
            overlays
          ];
        };

      # Every ./pkgs/<name>/update.sh pins a version and hash for something
      # nixpkgs does not carry, so they rewrite files in the checkout rather
      # than producing a store path. This just runs all of them in one go.
      update-pkgs = pkgs.writeShellApplication {
        name = "update-pkgs";
        runtimeInputs = with pkgs; [
          git
          curl
          jq
          gnused
          gnutar
          gzip
          nodejs # npm, for lockfile resolution
          prefetch-npm-deps
          nix
        ];
        text = ''
          root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
          if [ -z "$root" ] || [ ! -f "$root/flake.nix" ]; then
            echo "error: run this from inside the nixos-config checkout" >&2
            exit 1
          fi

          shopt -s nullglob
          scripts=("$root"/pkgs/*/update.sh)
          if [ ''${#scripts[@]} -eq 0 ]; then
            echo "no pkgs/*/update.sh found"
            exit 0
          fi

          failed=()
          for script in "''${scripts[@]}"; do
            name="$(basename "$(dirname "$script")")"
            echo "==> $name"
            "$script" || failed+=("$name")
          done

          if [ ''${#failed[@]} -gt 0 ]; then
            echo
            echo "failed: ''${failed[*]}" >&2
            exit 1
          fi

          echo
          echo "all updates done - review with 'git diff', then rebuild"
        '';
      };
    in
    {
      nixosConfigurations = {
        flatnix = mkHost {
          hostname = "flatnix";
          pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOpKQ7mHkk7LXzlV95YahAg76K6llq2QFAKVqiiSMoHm";
        };

        slimnix = mkHost {
          hostname = "slimnix";
          pubKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJypu216HqvuovQMbSesFBOOp+NEA/egmhS32pE7CRjw";
        };
      };

      # `nix fmt`
      formatter."${system}" = pkgs.nixfmt-tree;

      packages."${system}" = {
        inherit update-pkgs;
      };

      # `nix run .#update-pkgs`
      apps."${system}".update-pkgs = {
        type = "app";
        program = nixpkgs.lib.getExe update-pkgs;
      };

      devShells."${system}" = {
        # Cross-compiling to x86_64-pc-windows-gnu. The mingw toolchain and
        # these three variables used to sit in the global profile and login
        # environment; they are only ever needed for a Windows target.
        # LIBCLANG_PATH stays global on purpose - bindgen wants it for any
        # target, not just this one.
        windows-cross =
          let
            mingwCC = pkgs.pkgsCross.mingwW64.stdenv.cc.override {
              extraBuildCommands = ''
                printf '%s ' '-L${pkgs.pkgsCross.mingwW64.windows.mcfgthreads}/lib' >> $out/nix-support/cc-ldflags
                printf '%s ' '-isystem ${pkgs.pkgsCross.mingwW64.windows.pthreads}/include' >> $out/nix-support/cc-cflags-before
                printf '%s ' '-isystem ${pkgs.pkgsCross.mingwW64.windows.mcfgthreads.dev}/include' >> $out/nix-support/cc-cflags-before
              '';
            };

            # napi-build requires a real Windows libnode.dll when
            # cross-compiling napi addons. Official Node.js Windows builds don't
            # ship one, so use a prebuilt shared-library Node from
            # github.com/alshdavid/libnode-prebuilt.
            libnode = pkgs.fetchzip {
              url = "https://github.com/alshdavid/libnode-prebuilt/releases/download/v22.18.0/libnode-windows-amd64.tar.gz";
              hash = "sha256-ED8F0HIdLAc2fd9l77Ox9D247bRusvs6+XAfXdglWQU=";
              stripRoot = false;
            };

            # A script rather than a zsh function, so it survives
            # `nix develop -c zsh` (shellHook runs in bash).
            gowinbuild = pkgs.writeShellApplication {
              name = "gowinbuild";
              runtimeInputs = [ mingwCC ];
              text = ''
                CC=x86_64-w64-mingw32-gcc \
                CXX=x86_64-w64-mingw32-g++ \
                CGO_ENABLED=1 \
                GOOS=windows \
                GOARCH=amd64 \
                  go build "$@"
              '';
            };
          in
          pkgs.mkShellNoCC {
            packages = [
              mingwCC
              gowinbuild
            ];

            env = {
              CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUSTFLAGS =
                "-L native=${pkgs.pkgsCross.mingwW64.windows.pthreads}/lib "
                + "-L native=${pkgs.pkgsCross.mingwW64.windows.mcfgthreads}/lib "
                + "-C link-arg=-lmcfgthread";

              LIBNODE_PATH = "${libnode}";

              # bindgen needs mingw headers when cross-compiling to windows
              BINDGEN_EXTRA_CLANG_ARGS_x86_64_pc_windows_gnu = "-isystem ${pkgs.pkgsCross.mingwW64.stdenv.cc.libc.dev}/include";
            };

            shellHook = ''
              export SHELL_NAME="''${SHELL_NAME}''${SHELL_NAME:+>}windows-cross"
            '';
          };

        # Per-project services and tooling, kept out of the global profile
        # because they are large and only wanted inside specific projects.
        project-tools = pkgs.mkShellNoCC {
          packages = [
            pkgs.clickhouse
            pkgs.cbtemulator
            pkgs.firecracker
            pkgs.pulumi
            pkgs.pulumiPackages.pulumi-go
          ];

          shellHook = ''
            export SHELL_NAME="''${SHELL_NAME}''${SHELL_NAME:+>}project-tools"
          '';
        };

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
              export ENCORE_DEV_DIR="$_encore_base"

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
