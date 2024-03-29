{ pkgs, ... }: {
  home.packages = with pkgs; [
    swayidle
    swaylock
    wl-clipboard
  ];

  wayland.windowManager.sway = {
    enable = true;

    extraSessionCommands = ''
      eval $(gnome-keyring-daemon --daemonize)
      export SSH_AUTH_SOCK
    '';

    config = rec {
      modifier = "Mod4";
      terminal = "alacritty"; 

      gaps = {
        smartGaps = true;
        inner = 2;
      };

      input = {
        "type:touchpad" = {
          natural_scroll = "enabled";
	};
      };

      output = {
        eDP-1 = {
          scale = "1";
	};
      };
    };
  };
}
