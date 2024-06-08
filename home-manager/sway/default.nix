{ pkgs, ... }: {
  home.packages = with pkgs; [
    wl-clipboard
    nwg-displays
  ];

  imports = [
    ./waybar.nix
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    extraConfig = {
      display-drun = "Application";
      display-window = "Windows";
      drun-display-format = "{name}";
      modi = "window,drun,run";
      show-icons = true;
    };
  };

  programs.swaylock.enable = true;

  services.swayidle.enable = true;

  wayland.windowManager.sway =
    let
      mod = "Mod4";
    in
    {
      enable = true;

      extraSessionCommands = ''
        eval $(gnome-keyring-daemon --daemonize)
        export SSH_AUTH_SOCK
      '';

      extraConfig = ''
        set $windowswitcher 'rofi -show window'
        bindsym ${mod}+Tab exec $windowswitcher

        # Lock screen
        bindsym ${mod}+Shift+Escape exec swaynag -t warning -m 'Lock system?' -B 'Yes' 'swaylock -f -c 000000; pkill swaynag'
      '';

      config = {
        defaultWorkspace = "workspace number 1";

        modifier = mod;
        terminal = "alacritty";

        left = "h";
        down = "j";
        up = "k";
        right = "l";

        menu = "'${pkgs.rofi}/bin/rofi -modi drun,window,run -show drun'";

        bars = [{ command = "${pkgs.waybar}/bin/waybar"; }];

        gaps = {
          smartGaps = true;
          inner = 2;
          outer = 4;
        };

        input = {
          "type:touchpad" = {
            natural_scroll = "enabled";
          };
          "*" = {
            xkb_layout = "us,se";
            xkb_variant = "intl,";
            xkb_options = "grp:alt_space_toggle";
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
