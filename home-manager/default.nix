{ pkgs, inputs, ... }:
let
  inherit (inputs.nix-colors.lib-contrib { inherit pkgs; }) gtkThemeFromScheme;
  colorscheme = inputs.nix-colors.colorSchemes.ayu-dark;
in
{
  imports = [
    ./firefox.nix
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
    NIXOS_OZONE_WL = "1";
    MOZ_ENABLE_WAYLAND = "1";
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
    unstable.claude-code

    which
    tree
    btop
    lsof
    file
    linuxPackages.perf
    usbutils
    whois

    slack
    discord
    zulip

    dconf
    grim
    slurp
    dmenu
    kalker
    graphviz

    font-awesome
    powerline-fonts
    powerline-symbols
    nerd-fonts.symbols-only

    kubectl
    kubectx
    dive
    websocat
    dig
    whois
    # use unstable until: https://github.com/NixOS/nixpkgs/pull/352221
    unstable.pulumi
    unstable.pulumiPackages.pulumi-go
    cloudflared
    podman-compose
    (runCommand "podman-docker-compose-compat" { } ''
      mkdir -p $out/bin
      ln -s ${pkgs.podman-compose}/bin/podman-compose $out/bin/docker-compose
    '')
    # podman-desktop
    podman-tui
    cbtemulator
    overmind
    # use unstable until: https://github.com/NixOS/nixpkgs/issues/438765
    unstable.tailscale
    firecracker
    pgcli
    buf

    openssl
    gnumake
    pkg-config
    protobuf
    cmake
    gcc
    llvm
    rustup
    pkgsCross.mingwW64.windows.pthreads
    pkgsCross.mingwW64.windows.mcfgthreads
    (pkgsCross.mingwW64.stdenv.cc.override
      {
        extraBuildCommands = ''printf '%s ' '-L${pkgsCross.mingwW64.windows.mcfgthreads}/lib' >> $out/nix-support/cc-ldflags'';
      })
    go
    bun
    nodejs_22
    nodePackages.pnpm
    nodePackages.yarn
    nodePackages.vercel
    python3
    typescript
    zig
    musl
    musl.dev

    unstable.code-cursor

    drm_info

    gimp
    obsidian
    pavucontrol
    obs-studio
    mplayer
    spotify
    chromium

    mypkgs.mirror

    wlr-randr
  ];

  home.file.".config/containers/registries.conf".text = ''
    unqualified-search-registries = ["docker.io"]
  '';

  home.file.".config/dive/config.yaml".text = ''
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
      name = colorscheme.slug;
      package = gtkThemeFromScheme { scheme = colorscheme; };
    };

    iconTheme = {
      name = "Papirus";
      package = pkgs.papirus-icon-theme;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
  };

  dconf.settings."org/gnome/desktop/interface".color-scheme = "prefer-dark";

  home.stateVersion = "24.05";

  # Home manager manages home manager
  programs.home-manager.enable = true;
}
