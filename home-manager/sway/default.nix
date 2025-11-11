{ pkgs, lib, config, ... }: {
  home.packages = with pkgs; [
    wl-clipboard
    nwg-displays
    sway-contrib.grimshot
    chayang
    swayimg
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

  services.swayidle = {
    enable = true;

    timeouts = [
      { timeout = 300; command = "${pkgs.chayang}/bin/chayang && ${pkgs.swaylock}/bin/swaylock -f -c 000000"; }
      { timeout = 600; command = "${pkgs.sway}/bin/swaymsg \"output * dpms off\""; resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on, output * enable\""; }
      { timeout = 900; command = "${pkgs.systemd}/bin/systemctl suspend"; }
    ];
    events = [
      { event = "before-sleep"; command = "${pkgs.swaylock}/bin/swaylock -f -c 000000"; }
    ];

  };

  home.file.".config/sway/background.png" = {
    source = ./background.png;
  };

  wayland.windowManager.sway =
    let
      mod = "Mod4";
      grimshot = "${pkgs.sway-contrib.grimshot}/bin/grimshot";
      rofi = "${pkgs.rofi}/bin/rofi";
      slurp = "${pkgs.slurp}/bin/slurp";
      grim = "${pkgs.grim}/bin/grim";
    in
    {
      enable = true;
      systemd.enable = true;
      checkConfig = false;

      extraSessionCommands = ''
        eval $(gnome-keyring-daemon --daemonize)
        export SSH_AUTH_SOCK

        # Import environment into systemd to ensure portals get correct variables
        systemctl --user import-environment PATH XDG_DATA_DIRS XDG_CONFIG_DIRS GIO_EXTRA_MODULES
        dbus-update-activation-environment --systemd PATH XDG_DATA_DIRS XDG_CONFIG_DIRS GIO_EXTRA_MODULES
      '';

      wrapperFeatures.gtk = true;

      config = {
        defaultWorkspace = "workspace number 1";

        modifier = mod;
        terminal = "alacritty";

        left = "h";
        down = "j";
        up = "k";
        right = "l";

        keybindings = lib.mkOptionDefault {
          "${mod}+Tab" = "exec ${rofi} -show window";
          "${mod}+Shift+Escape" = "exec swaynag -t warning -m 'Lock system?' -B 'Yes' 'swaylock -f -c 000000; pkill swaynag'";

          # Print selection to clipboard
          "Print" = "exec ${slurp} | ${grim} -g - - | wl-copy -t image/png";
          # Print selection to file
          "Ctrl+Print" = "exec ${slurp} | ${grim} -g -";
          # Print focused window to clipboard
          "Shift+Print" = "exec ${grimshot} copy active";
          # Print focused window to file
          "Ctrl+Shift+Print" = "exec ${grimshot} save active";
        };

        menu = "'${rofi} -modi drun,window,run -show drun'";

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
          "*" = {
            bg = "${config.xdg.configHome}/sway/background.png center #282828";
          };
          eDP-1 = {
            scale = "1";
          };
        };
      };
    };
}
