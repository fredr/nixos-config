{ config, pkgs, ... }: {
  imports = [
    ./firefox.nix
    ./sway.nix
    ./git.nix
    ./alacritty.nix
    ./neovim.nix
    ./zsh.nix
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
  ];

  home.stateVersion = "23.11";

  # Home manager manages home manager
  programs.home-manager.enable = true;
}
