{ pkgs, ... }: {
  home.packages = with pkgs; [
    swayidle
    swaylock
    wl-clipboard
  ];

  wayland.windowManager.sway = {
    enable = true;
    config = rec {
      modifier = "Mod4";
      terminal = "alacritty"; 
    };
  };
}
