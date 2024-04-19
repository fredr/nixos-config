{ pkgs, ... }: {
  home.packages = with pkgs; [
    wl-clipboard
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
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    settings = {
      mainBar = {
        layer = "top";
	position = "top";
	height = 30;
	spacing = 4;
	modules-left = [ "sway/workspaces" "sway/mode" "sway/scratchpad" ];
	modules-center = [ "sway/window" ];
	modules-right = [ "mpd" "idle_inhibitor" "custom/k8s" "network" "cpu" "memory" "backlight" "sway/language" "battery" "battery#bat2" "clock" "tray" ];

       "sway/mode" = {
           format = "<span style=\"italic\">{}</span>";
       };
       "sway/scratchpad" = {
           format = "{icon} {count}";
           show-empty = false;
           format-icons = ["" ""];
           tooltip = true;
           tooltip-format = "{app}: {title}";
       };
       "mpd" = {
           format = "{stateIcon} {consumeIcon}{randomIcon}{repeatIcon}{singleIcon}{artist} - {album} - {title} ({elapsedTime:%M:%S}/{totalTime:%M:%S}) ⸨{songPosition}|{queueLength}⸩ {volume}% ";
           format-disconnected = "Disconnected ";
           format-stopped = "{consumeIcon}{randomIcon}{repeatIcon}{singleIcon}Stopped ";
           unknown-tag = "N/A";
           interval = 2;
           consume-icons = {
               on = " ";
           };
           random-icons = {
               off = "<span color=\"#f53c3c\"></span> ";
               on = " ";
           };
           repeat-icons = {
               on = " ";
           };
           single-icons = {
               on = "1 ";
           };
           state-icons = {
               paused = "";
               playing = "";
           };
           tooltip-format = "MPD (connected)";
           tooltip-format-disconnected = "MPD (disconnected)";
       };
       idle_inhibitor = {
           format = "{icon}";
           format-icons = {
               activated = "";
               deactivated = "";
           };
       };
       "tray" = {
           icon-size = 21;
           spacing = 10;
       };
       "clock" = {
           tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
           format-alt = "{:%Y-%m-%d}";
       };
       "cpu" = {
           format = "{usage}% ";
           tooltip = false;
       };
       "memory" = {
           format = "{}% ";
       };
       "backlight" = {
           format = "{icon}";
           format-icons = ["" "" "" "" "" "" "" "" ""];
       };
       "battery" = {
           states = {
               good = 95;
               warning = 30;
               critical = 15;
           };
           format = "{capacity}% {icon}";
           format-charging = "{capacity}% ";
           format-plugged = "{capacity}% ";
           format-alt = "{time} {icon}";
           format-good = ""; # An empty format will hide the module
           format-full = "";
           format-icons = ["" "" "" "" ""];
       };
       "battery#bat2" = {
           bat = "BAT2";
       };
       "network" = {
           format-wifi = "";
           tooltip-format-wifi = "{essid} ({signalStrength}%) ";
           format-ethernet = "{ipaddr}/{cidr} ";
           tooltip-format = "{ifname} via {gwaddr} ";
           format-linked = "{ifname} (No IP) ";
           format-disconnected = "Disconnected ⚠";
           format-alt = "{ifname}: {ipaddr}/{cidr}";
       };
       "custom/k8s" = {
           format = "☁️ {}";
	   exec = pkgs.writeShellScript "current context" ''
	     ${pkgs.kubectl}/bin/kubectl config current-context
	   '';
           interval = 5;
	   on-click = pkgs.writeShellScript "choose context" ''
	     ${pkgs.kubectx}/bin/kubectx $(${pkgs.kubectx}/bin/kubectx | ${pkgs.rofi}/bin/rofi -dmenu -p 'Context')
	   '';
       };
      };
    };
    style = ''
    * {
        /* `otf-font-awesome` is required to be installed for icons */
        font-family: FontAwesome, Roboto, Helvetica, Arial, sans-serif;
        font-size: 13px;
    }
    window#waybar {
        background-color: rgba(43, 48, 59, 0.5);
        border-bottom: 3px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
        transition-property: background-color;
        transition-duration: .5s;
    }
    window#waybar.hidden {
        opacity: 0.2;
    }
    window#waybar.termite {
        background-color: #3F3F3F;
    }
    window#waybar.chromium {
        background-color: #000000;
        border: none;
    }
    button {
        /* Use box-shadow instead of border so the text isn't offset */
        box-shadow: inset 0 -3px transparent;
        /* Avoid rounded borders under each button name */
        border: none;
        border-radius: 0;
    }
    /* https://github.com/Alexays/Waybar/wiki/FAQ#the-workspace-buttons-have-a-strange-hover-effect */
    button:hover {
        background: inherit;
        box-shadow: inset 0 -3px #ffffff;
    }
    #workspaces button {
        padding: 0 5px;
        background-color: transparent;
        color: #ffffff;
    }
    #workspaces button:hover {
        background: rgba(0, 0, 0, 0.2);
    }
    #workspaces button.focused {
        background-color: #64727D;
        box-shadow: inset 0 -3px #ffffff;
    }
    #workspaces button.urgent {
        background-color: #eb4d4b;
    }
    #mode {
        background-color: #64727D;
        border-bottom: 3px solid #ffffff;
    }
    #clock,
    #battery,
    #cpu,
    #memory,
    #temperature,
    #backlight,
    #network,
    #custom-k8s,
    #tray,
    #mode,
    #idle_inhibitor,
    #scratchpad,
    #language {
        padding: 0 10px;
        border-bottom: 3px solid rgba(100, 114, 125, 0.5);
        color: #ffffff;
    }
    #window,
    #workspaces {
        margin: 0 4px;
    }
    /* If workspaces is the leftmost module, omit left margin */
    .modules-left > widget:first-child > #workspaces {
        margin-left: 0;
    }
    /* If workspaces is the rightmost module, omit right margin */
    .modules-right > widget:last-child > #workspaces {
        margin-right: 0;
    }
    #clock {
        background-color: #64223A;
    }
    #battery {
        background-color: #ffffff;
        color: #000000;
    }
    #battery.charging, #battery.plugged {
        color: #ffffff;
        background-color: #26A65B;
    }
    @keyframes blink {
        to {
            background-color: #ffffff;
            color: #000000;
        }
    }
    #battery.critical:not(.charging) {
        background-color: #f53c3c;
        color: #ffffff;
        animation-name: blink;
        animation-duration: 0.5s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
        animation-direction: alternate;
    }
    label:focus {
        background-color: #000000;
    }
    #cpu {
        background-color: #2ecc71;
        color: #000000;
        min-width: 50px;
    }
    #memory {
        background-color: #9b59b6;
        min-width: 50px;
    }
    #disk {
        background-color: #964B00;
    }
    #backlight {
        background-color: #90b1b1;
    }
    #network {
        background-color: #2980b9;
    }
    #network.disconnected {
        background-color: #f53c3c;
    }
    #custom-k8s {
        background-color: #66aa99;
        color: #333;
    }
    #tray {
        background-color: #2980b9;
    }
    #tray > .passive {
        -gtk-icon-effect: dim;
    }
    #tray > .needs-attention {
        -gtk-icon-effect: highlight;
        background-color: #eb4d4b;
    }
    #idle_inhibitor {
        background-color: #2d3436;
    }
    #idle_inhibitor.activated {
        background-color: #ecf0f1;
        color: #2d3436;
    }
    #language {
        background: #00b093;
        color: #740864;
        padding: 0 5px;
        margin: 0;
        min-width: 16px;
    }
    #keyboard-state {
        background: #97e1ad;
        color: #000000;
        padding: 0 0px;
        margin: 0 5px;
        min-width: 16px;
    }
    #keyboard-state > label {
        padding: 0 5px;
    }
    #keyboard-state > label.locked {
        background: rgba(0, 0, 0, 0.2);
    }
    #scratchpad {
        background: rgba(0, 0, 0, 0.2);
    }
    #scratchpad.empty {
        background-color: transparent;
    }
    '';
  };

  services.swayidle.enable = true;

  wayland.windowManager.sway = let
    mod = "Mod4";
  in {
    enable = true;

    extraSessionCommands = ''
      eval $(gnome-keyring-daemon --daemonize)
      export SSH_AUTH_SOCK
    '';

    extraConfig = ''
      set $windowswitcher 'rofi -show window'
      bindsym ${mod}+Tab exec $windowswitcher
    '';

    config = rec {
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
