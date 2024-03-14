{ config, pkgs, ... }:

{
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

  programs.firefox.enable = true;

  programs.neovim = {
    enable = true;
    defaultEditor = true;
  };

  programs.git = {
    enable = true;
    userName = "fredr";
    userEmail = "fredrik@enestad.com";
  };

  programs.alacritty = {
    enable = true;

    settings = {
      env.TERM = "xterm-256color";
      font = {
        size = 12;
	draw_bold_text_with_bright_colors = true;
      };
      scrolling.multiplier = 5;
    };
  };

  programs.zsh = {
    enable = true;
    enableCompletion = true;
    enableAutosuggestions = true;
    syntaxHighlighting.enable = true;

    shellAliases = {
      ll = "ls -l";
      nixup = "sudo nixos-rebuild switch";
      gst = "git status";
    };
  
    history.size = 10000;
    history.path = "${config.xdg.dataHome}/zsh/history";
  };

  home.stateVersion = "23.11";

  # Home manager manages home manager
  programs.home-manager.enable = true;
}
