{ config, pkgs, ... }:
{
  imports = [
    ./firefox.nix
    ./chrome.nix
    ./mime.nix
    ./sway
    ./git.nix
    ./alacritty.nix
    ./neovim
    ./zsh.nix
    ./gcloud.nix
    ./kanshi.nix
    ./zed.nix
  ];

  home.username = "fredr";
  home.homeDirectory = "/home/fredr";

  home.sessionVariables = {
    # Read by Electron/Chromium apps (zed, obsidian, slack, discord, chrome).
    NIXOS_OZONE_WL = "1";

    # gnome-keyring's SSH agent socket. Here rather than in sway's wrapper so
    # uwsm's env preloader picks it up for user services too.
    SSH_AUTH_SOCK = "$XDG_RUNTIME_DIR/gcr/ssh";
  };

  home.packages = with pkgs; [
    ripgrep
    jq
    yq-go
    eza
    fzf
    bat
    cue
    llm
    killall
    mypkgs.claude-code
    nitch
    dysk
    mypkgs.screenpipe

    which
    tree
    btop
    lsof
    file
    perf
    usbutils
    whois

    slack
    discord

    grim
    slurp
    kalker
    graphviz

    font-awesome
    powerline-fonts
    powerline-symbols
    nerd-fonts.symbols-only
    nerd-fonts.jetbrains-mono

    kubectl
    kubectx
    dive
    websocat
    dig
    cloudflared
    podman-compose
    (runCommand "podman-docker-compose-compat" { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.podman-compose}/bin/podman-compose $out/bin/docker-compose
    '')
    podman-desktop
    podman-tui
    overmind
    pgcli
    buf
    dust
    grpcurl
    bubblewrap
    libsecret

    openssl
    gnumake
    pkg-config
    protobuf
    cmake
    nasm
    gcc
    llvm
    rustup
    go
    bun
    nodejs_22
    pnpm
    yarn
    mypkgs.vercel
    python3
    typescript
    zig
    musl
    musl.dev
    gdb
    lldb
    delve
    uv

    drm_info

    gimp
    obsidian
    pavucontrol
    obs-studio
    mplayer
    spotify

    mypkgs.mirror

    wlr-randr
    file-roller
    (pkgs.writeShellApplication {
      name = "ns";
      runtimeInputs = with pkgs; [
        fzf
        nix-search-tv
      ];
      excludeShellChecks = [ "SC2016" ];
      text = builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh";
    })
  ];

  # Claude Code writes to settings.json at runtime (/effort, /model, ...), so it
  # can't be a read-only store symlink. Instead merge the managed keys into the
  # existing file on activation.
  home.activation.claudeSettings =
    let
      managed = pkgs.writeText "claude-managed.json" (
        builtins.toJSON {
          permissions = {
            defaultMode = "default";
            allow = [ "Read" ];
          };
          enabledPlugins = {
            "gopls-lsp@claude-plugins-official" = true;
            "rust-analyzer-lsp@claude-plugins-official" = true;
          };
        }
      );
    in
    config.lib.dag.entryAfter [ "linkGeneration" ] ''
      settings="$HOME/.claude/settings.json"
      run mkdir -p "$HOME/.claude"
      existing='{}'
      if [ -e "$settings" ]; then
        existing="$(cat "$settings")"
      fi
      # Replace a leftover store symlink with a regular file
      [ -L "$settings" ] && run rm "$settings"
      merged="$(echo "$existing" | ${pkgs.jq}/bin/jq -S --slurpfile m ${managed} '. * $m[0]')"
      if [ -z "''${DRY_RUN:-}" ]; then
        echo "$merged" > "$settings"
      fi
    '';

  xdg.configFile."containers/registries.conf".text = ''
    unqualified-search-registries = ["docker.io"]
  '';

  xdg.configFile."dive/config.yaml".text = ''
    container-engine: podman
    source: podman
  '';

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  programs.atuin.enable = true;
  programs.atuin.settings = {
    filter_mode = "session";
    search_mode = "fulltext";
    style = "compact";
    show_preview = true;
    enter_accept = false;
  };

  programs.gh = {
    enable = true;
    settings.git_protocol = "ssh";
    settings.editor = "nvim";
  };

  programs.zathura.enable = true;

  fonts.fontconfig.enable = true;

  gtk = {
    enable = true;

    theme = {
      name = "catppuccin-mocha-blue-standard";
      package = pkgs.catppuccin-gtk.override {
        accents = [ "blue" ];
        variant = "mocha";
      };
    };

    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.catppuccin-papirus-folders.override {
        flavor = "mocha";
        accent = "blue";
      };
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4 = {
      theme = config.gtk.theme;
      extraConfig = {
        gtk-application-prefer-dark-theme = 1;
      };
    };
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.stateVersion = "26.05";

  # Home manager manages home manager
  programs.home-manager.enable = true;
}
