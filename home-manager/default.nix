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
    ./rust.nix
  ];

  home.username = "fredr";
  home.homeDirectory = "/home/fredr";

  home.packages = with pkgs; [
    ripgrep
    jq
    yq-go
    eza
    fzf

    which
    tree
    btop
    lsof

    slack
    discord

    dconf

    font-awesome
    powerline-fonts
    powerline-symbols
    nerdfonts

    kubectl
    kubectx
    dive
    websocat
    dig

    gcc
    openssl
    gnumake
    protobuf
    cmake

    go
    nodejs_22

    drm_info

    gimp
    obsidian
    pavucontrol
  ];

  home.file.".config/dive/config.yaml".text = ''
    container-engine: podman
    source: podman
  '';

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
