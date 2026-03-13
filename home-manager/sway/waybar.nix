{ pkgs, ... }: {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 28;
        margin-top = 6;
        margin-left = 10;
        margin-right = 10;
        spacing = 0;
        modules-left = [ "sway/workspaces" "sway/mode" "sway/scratchpad" "sway/window" "mpris" ];
        modules-center = [ ];
        modules-right = [ "privacy" "custom/updates" "idle_inhibitor" "pulseaudio" "bluetooth" "network" "cpu" "memory" "backlight" "sway/language" "battery" "battery#bat2" "clock" "tray" ];

        "sway/workspaces" = {
          disable-scroll = true;
          all-outputs = false;
        };
        "sway/mode" = {
          format = "{}";
        };
        "sway/scratchpad" = {
          format = "{icon} {count}";
          show-empty = false;
          format-icons = [ "󰖲" "󰖲" ];
          tooltip = true;
          tooltip-format = "{app}: {title}";
        };
        "mpris" = {
          format = "{player_icon} {title} - {artist}";
          format-paused = "{player_icon} {status_icon} {title} - {artist}";
          player-icons = {
            default = "▶";
            spotify = "";
            firefox = "";
          };
          status-icons = {
            paused = "⏸";
          };
          max-length = 40;
          on-click = "${pkgs.playerctl}/bin/playerctl play-pause";
          on-click-right = "${pkgs.playerctl}/bin/playerctl next";
          on-scroll-up = "${pkgs.playerctl}/bin/playerctl volume 0.05+";
          on-scroll-down = "${pkgs.playerctl}/bin/playerctl volume 0.05-";
        };
        "custom/updates" = {
          format = "󰏔 {}";
          exec = pkgs.writeShellScript "check-updates" ''
            count=$(${pkgs.nix}/bin/nix store diff-closures /run/current-system /nix/var/nix/profiles/system 2>/dev/null | grep -c '→' || true)
            if [ "$count" -gt 0 ]; then
              echo "$count"
            else
              echo ""
            fi
          '';
          interval = 3600;
          tooltip-format = "pending system updates";
          on-click = "${pkgs.alacritty}/bin/alacritty -e bash -c 'sudo nixos-rebuild switch --flake /home/fredr/nixos-config; read -p \"Press enter to close\"'";
        };
        "privacy" = {
          icon-spacing = 4;
          icon-size = 14;
          transition-duration = 250;
          modules = [
            { type = "screenshare"; tooltip = true; tooltip-icon-size = 20; }
            { type = "audio-in"; tooltip = true; tooltip-icon-size = 20; }
            { type = "audio-out"; tooltip = true; tooltip-icon-size = 20; }
          ];
        };
        idle_inhibitor = {
          format = "{icon}";
          format-icons = {
            activated = "󰅶";
            deactivated = "󰾪";
          };
        };
        "pulseaudio" = {
          format = "{icon} {volume}%";
          format-bluetooth = "󰂱 {volume}%";
          format-muted = "󰝟";
          format-icons = {
            headphone = "󰋋";
            default = [ "󰕿" "󰖀" "󰕾" ];
          };
          scroll-step = 5;
          on-click = "${pkgs.pavucontrol}/bin/pavucontrol";
          on-click-right = "${pkgs.pulseaudio}/bin/pactl set-sink-mute @DEFAULT_SINK@ toggle";
        };
        "tray" = {
          icon-size = 18;
          spacing = 8;
        };
        "clock" = {
          format = "{:%H:%M}";
          format-alt = "{:%a %b %d}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
        "cpu" = {
          format = " {usage}%";
          tooltip = false;
          on-click = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.btop}/bin/btop";
        };
        "memory" = {
          format = " {}%";
          on-click = "${pkgs.alacritty}/bin/alacritty -e ${pkgs.btop}/bin/btop";
        };
        "backlight" = {
          format = "{icon}";
          format-icons = [ "󰃞" "󰃟" "󰃠" ];
          scroll-step = 5;
        };
        "battery" = {
          states = {
            warning = 30;
            critical = 15;
          };
          format = "{icon}";
          format-charging = "{icon}";
          format-plugged = "󰂄";
          format-alt = "{icon} {capacity}% {time}";
          format-icons = [ "󰁺" "󰁻" "󰁼" "󰁽" "󰁾" "󰁿" "󰂀" "󰂁" "󰂂" "󰁹" ];
          format-charging-icons = [ "󰢜" "󰂆" "󰂇" "󰂈" "󰢝" "󰂉" "󰢞" "󰂊" "󰂋" "󰂅" ];
          tooltip-format = "{capacity}% - {timeTo}";
        };
        "battery#bat2" = {
          bat = "BAT2";
        };
        "bluetooth" = {
          format = "󰂯";
          format-connected = "󰂱 {device_alias}";
          format-connected-battery = "󰂱 {device_alias} {device_battery_percentage}%";
          format-disabled = "󰂲";
          format-off = "󰂲";
          tooltip-format = "{controller_alias}\t{controller_address}\n\n{num_connections} connected";
          tooltip-format-connected = "{controller_alias}\t{controller_address}\n\n{num_connections} connected\n\n{device_enumerate}";
          tooltip-format-enumerate-connected = "{device_alias}\t{device_address}";
          tooltip-format-enumerate-connected-battery = "{device_alias}\t{device_address}\t{device_battery_percentage}%";
          on-click = "blueman-manager";
        };
        "network" = {
          format-wifi = "{icon}";
          format-icons = [ "󰤟" "󰤢" "󰤥" "󰤨" ];
          format-ethernet = "󰈀";
          tooltip-format-wifi = "{essid} ({signalStrength}%)";
          tooltip-format = "{ifname} via {gwaddr}";
          format-linked = "󰈀 No IP";
          format-disconnected = "󰤭";
          format-alt = "{ifname}: {ipaddr}/{cidr}";
          on-click-right = "${pkgs.alacritty}/bin/alacritty -e nmtui";
        };
      };
    };
    style = ./waybar.css;
  };

}
