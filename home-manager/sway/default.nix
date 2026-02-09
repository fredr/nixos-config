{ pkgs, lib, config, ... }: {
  # Protect sway-related services from systemd-oomd
  systemd.user.services.sway-session.Service.ManagedOOMPreference = "avoid";
  systemd.user.services.waybar.Service.ManagedOOMPreference = "avoid";
  systemd.user.services.swayidle.Service.ManagedOOMPreference = "avoid";

  home.packages = with pkgs; [
    wl-clipboard
    nwg-displays
    sway-contrib.grimshot
    chayang
    swayimg
    gcr # Provides org.gnome.keyring.SystemPrompter
    jq
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

      # scratchpad toggle scripts
      toggle_terminal = pkgs.writeShellScript "toggle-terminal-scratchpad" ''
        if ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '.. | select(.app_id? == "scratchpad_terminal")' > /dev/null; then
          ${pkgs.sway}/bin/swaymsg '[app_id="scratchpad_terminal"]' scratchpad show
        else
          ${pkgs.alacritty}/bin/alacritty --class scratchpad_terminal
        fi
      '';

      toggle_obsidian = pkgs.writeShellScript "toggle-obsidian-scratchpad" ''
        if ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '.. | select(.app_id? == "obsidian")' > /dev/null; then
          ${pkgs.sway}/bin/swaymsg '[app_id="obsidian"]' scratchpad show
        else
          ${pkgs.obsidian}/bin/obsidian
        fi
      '';

      toggle_firefox = pkgs.writeShellScript "toggle-firefox-scratchpad" ''
        if ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '.. | select(.app_id? == "scratchpad_firefox")' > /dev/null; then
          ${pkgs.sway}/bin/swaymsg '[app_id="scratchpad_firefox"]' scratchpad show
        else
          ${pkgs.firefox}/bin/firefox --name scratchpad_firefox --no-remote -P scratchpad
        fi
      '';
    in
    {
      enable = true;
      systemd.enable = true;
      checkConfig = false;

      extraSessionCommands = ''
        # Set SSH_AUTH_SOCK to gnome-keyring's SSH agent socket
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"

        # flickering in zed, see https://github.com/swaywm/sway/issues/8755
        export WLR_RENDER_NO_EXPLICIT_SYNC=1

        # Import environment into systemd to ensure portals and other services get correct variables
        systemctl --user import-environment SSH_AUTH_SOCK PATH XDG_DATA_DIRS XDG_CONFIG_DIRS GIO_EXTRA_MODULES
        dbus-update-activation-environment --systemd SSH_AUTH_SOCK PATH XDG_DATA_DIRS XDG_CONFIG_DIRS GIO_EXTRA_MODULES
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

          # Scratchpad toggles
          "${mod}+t" = "exec ${toggle_terminal}";
          "${mod}+o" = "exec ${toggle_obsidian}";
          "${mod}+i" = "exec ${toggle_firefox}";
        };

        # Window commands (for_window rules)
        window.commands = [
          {
            criteria = { app_id = "scratchpad_terminal"; };
            command = "move scratchpad, scratchpad show";
          }
          {
            criteria = { app_id = "obsidian"; };
            command = "move scratchpad, scratchpad show";
          }
          {
            criteria = { app_id = "scratchpad_firefox"; };
            command = "move scratchpad, scratchpad show";
          }
        ];

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
