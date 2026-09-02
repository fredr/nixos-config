{
  pkgs,
  lib,
  config,
  ...
}:
{
  # Protect sway-related services from systemd-oomd
  systemd.user.services.waybar.Service.ManagedOOMPreference = "avoid";
  systemd.user.services.swayidle.Service.ManagedOOMPreference = "avoid";

  home.packages = with pkgs; [
    wl-clipboard
    xclip
    nwg-displays
    sway-contrib.grimshot
    chayang
    swayimg
    gcr # Provides org.gnome.keyring.SystemPrompter
    playerctl
  ];

  imports = [
    ./waybar.nix
  ];

  programs.rofi = {
    enable = true;
    package = pkgs.rofi;

    theme = "catppuccin-mocha";

    extraConfig = {
      display-drun = "Application";
      display-window = "Windows";
      drun-display-format = "{name}";
      modi = "window,drun,run";
      show-icons = true;

      # Run mode launches into app-graphical.slice instead of the compositor's
      # cgroup. drun has no equivalent hook and rofi has no systemd integration
      # of its own, so desktop entries still land in sway's cgroup — survivable
      # only because of OOMPolicy=continue (see modules/desktop.nix).
      run-command = "${pkgs.uwsm}/bin/uwsm app -- {cmd}";
    };
  };

  xdg.dataFile."rofi/themes/catppuccin-mocha.rasi".text = ''
    * {
      bg: #1e1e2e;
      bg-alt: #313244;
      fg: #cdd6f4;
      fg-alt: #a6adc8;
      blue: #89b4fa;

      background-color: @bg;
      border: 0;
      margin: 0;
      padding: 0;
      spacing: 0;
    }

    window {
      width: 500px;
      border: 2px;
      border-color: @bg-alt;
      border-radius: 12px;
    }

    inputbar {
      children: [prompt, entry];
      background-color: @bg-alt;
      border-radius: 12px 12px 0 0;
      padding: 12px;
    }

    prompt {
      background-color: transparent;
      text-color: @blue;
      padding: 0 8px 0 0;
    }

    entry {
      background-color: transparent;
      text-color: @fg;
      placeholder: "Search...";
      placeholder-color: @fg-alt;
    }

    listview {
      lines: 8;
      columns: 1;
      fixed-height: false;
      background-color: @bg;
      padding: 4px 0;
    }

    element {
      padding: 8px 12px;
      background-color: transparent;
      text-color: @fg-alt;
    }

    element selected {
      background-color: @bg-alt;
      text-color: @fg;
    }

    element-icon {
      size: 24px;
      padding: 0 8px 0 0;
      background-color: transparent;
    }

    element-text {
      background-color: transparent;
      text-color: inherit;
      vertical-align: 0.5;
    }
  '';

  programs.swaylock = {
    enable = true;
    settings = {
      color = "1e1e2e";
      inside-color = "1e1e2e";
      inside-clear-color = "1e1e2e";
      inside-ver-color = "1e1e2e";
      inside-wrong-color = "1e1e2e";
      ring-color = "585b70";
      ring-clear-color = "f9e2af";
      ring-ver-color = "89b4fa";
      ring-wrong-color = "f38ba8";
      key-hl-color = "a6e3a1";
      bs-hl-color = "f38ba8";
      text-color = "cdd6f4";
      text-clear-color = "cdd6f4";
      text-ver-color = "cdd6f4";
      text-wrong-color = "cdd6f4";
      line-color = "00000000";
      line-clear-color = "00000000";
      line-ver-color = "00000000";
      line-wrong-color = "00000000";
      separator-color = "00000000";
      indicator-radius = 100;
      indicator-thickness = 7;
    };
  };

  services.swayidle = {
    enable = true;

    timeouts = [
      {
        timeout = 300;
        command = "${pkgs.chayang}/bin/chayang && ${pkgs.swaylock}/bin/swaylock -f";
      }
      {
        timeout = 600;
        command = "${pkgs.sway}/bin/swaymsg \"output * dpms off\"";
        resumeCommand = "${pkgs.sway}/bin/swaymsg \"output * dpms on\"";
      }
      {
        timeout = 900;
        command = "${pkgs.systemd}/bin/systemctl suspend";
      }
    ];
    events = {
      "before-sleep" = "${pkgs.swaylock}/bin/swaylock -f";
    };
  };

  wayland.windowManager.sway =
    let
      mod = "Mod4";
      grimshot = "${pkgs.sway-contrib.grimshot}/bin/grimshot";
      rofi = "${pkgs.rofi}/bin/rofi";
      slurp = "${pkgs.slurp}/bin/slurp";
      grim = "${pkgs.grim}/bin/grim";

      # Same derivation the NixOS programs.uwsm module installs (useGlobalPkgs).
      uwsm = "${pkgs.uwsm}/bin/uwsm";

      # Launch apps in their own unit under app-graphical.slice rather than
      # inside the compositor's. A scope (the default) is forked by the caller,
      # so it inherits sway's environment and journal-connected stderr. Absolute
      # paths only, or uwsm resolves the first argument as a Desktop Entry ID.
      app = "${uwsm} app --";

      # scratchpad toggle scripts
      toggle_terminal = pkgs.writeShellScript "toggle-terminal-scratchpad" ''
        if ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '.. | select(.app_id? == "scratchpad_terminal")' > /dev/null; then
          ${pkgs.sway}/bin/swaymsg '[app_id="scratchpad_terminal"]' scratchpad show
        else
          ${app} ${pkgs.alacritty}/bin/alacritty --class scratchpad_terminal
        fi
      '';

      toggle_obsidian = pkgs.writeShellScript "toggle-obsidian-scratchpad" ''
        if ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '.. | select(.app_id? == "obsidian")' > /dev/null; then
          ${pkgs.sway}/bin/swaymsg '[app_id="obsidian"]' scratchpad show
        else
          ${app} ${pkgs.obsidian}/bin/obsidian
        fi
      '';

      reload_sway = pkgs.writeShellScript "reload-sway" ''
        idx=$(${pkgs.sway}/bin/swaymsg -t get_inputs \
          | ${pkgs.jq}/bin/jq -r '[.[] | select(.type == "keyboard") | .xkb_active_layout_index] | first // 0')
        ${pkgs.sway}/bin/swaymsg reload
        ${pkgs.kanshi}/bin/kanshictl reload
        ${pkgs.sway}/bin/swaymsg input type:keyboard xkb_switch_layout "$idx"
      '';

      toggle_firefox = pkgs.writeShellScript "toggle-firefox-scratchpad" ''
        if ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '.. | select(.app_id? == "scratchpad_firefox")' > /dev/null; then
          ${pkgs.sway}/bin/swaymsg '[app_id="scratchpad_firefox"]' scratchpad show
        else
          ${app} ${pkgs.firefox}/bin/firefox --name scratchpad_firefox --no-remote -P scratchpad
        fi
      '';

      # slimnotes is not packaged yet (unpublished), so this runs the cargo build
      # from the working tree. That binary dlopens wayland/vulkan at startup and
      # gets their paths from the dev shell, which sway's exec does not have — so
      # the library path is reproduced here. Both go away once it is a package;
      # the list mirrors `libraries` in the project's flake.nix.
      #
      # A service rather than a scope like the others, so a crash leaves a failed
      # unit behind rather than just a vanished window. Services don't inherit the
      # caller's environment, hence the explicit Environment= properties.
      slimnotes = "${config.home.homeDirectory}/projects/slimnotes/target/release/slimnotes";
      slimnotesLibs = pkgs.lib.makeLibraryPath (
        with pkgs;
        [
          fontconfig
          freetype
          wayland
          libxkbcommon
          libxcb
          libx11
          libxext
          libGL
          vulkan-loader
          openssl
          zlib
        ]
      );
      toggle_slimnotes = pkgs.writeShellScript "toggle-slimnotes-scratchpad" ''
        if ${pkgs.sway}/bin/swaymsg -t get_tree | ${pkgs.jq}/bin/jq -e '.. | select(.app_id? == "scratchpad_slimnotes")' > /dev/null; then
          ${pkgs.sway}/bin/swaymsg '[app_id="scratchpad_slimnotes"]' scratchpad show
        else
          ${uwsm} app -t service -a slimnotes \
            -p "Environment=RUST_BACKTRACE=1" \
            -p "Environment=LD_LIBRARY_PATH=${slimnotesLibs}:/run/opengl-driver/lib" \
            -- ${slimnotes} --app-id scratchpad_slimnotes
        fi
      '';
    in
    {
      enable = true;

      # uwsm owns the session (see programs.uwsm in modules/desktop.nix); this
      # would start a competing sway-session.target and import-environment.
      systemd.enable = false;

      # Only wlroots reads this, so it can stay in sway's own environment. Vars
      # that user services need go in home.sessionVariables instead, where the
      # uwsm env preloader picks them up.
      extraSessionCommands = ''
        # flickering in zed, see https://github.com/swaywm/sway/issues/8755
        export WLR_RENDER_NO_EXPLICIT_SYNC=1
      '';

      wrapperFeatures.gtk = true;

      config = {
        defaultWorkspace = "workspace number 1";

        # Exports WAYLAND_DISPLAY/DISPLAY to the systemd user environment and
        # marks the compositor unit started; without it the unit times out.
        # Needs no arguments: uwsm's sway plugin covers SWAYSOCK and XCURSOR_*,
        # and the env preloader already carries everything from the login shell.
        # Only vars sway sets late belong in the list.
        startup = [ { command = "${uwsm} finalize"; } ];

        modifier = mod;
        # Via uwsm app, so $mod+Return lands in app-graphical.slice like the
        # scratchpads do, and not in the compositor's own cgroup.
        terminal = "${app} ${pkgs.alacritty}/bin/alacritty";

        left = "h";
        down = "j";
        up = "k";
        right = "l";

        window = {
          border = 1;
          titlebar = false;
        };
        floating = {
          border = 1;
          titlebar = false;
        };

        colors = {
          focused = {
            border = "#585b70";
            background = "#313244";
            text = "#cdd6f4";
            indicator = "#585b70";
            childBorder = "#585b70";
          };
          focusedInactive = {
            border = "#313244";
            background = "#1e1e2e";
            text = "#cdd6f4";
            indicator = "#313244";
            childBorder = "#313244";
          };
          unfocused = {
            border = "#313244";
            background = "#1e1e2e";
            text = "#a6adc8";
            indicator = "#313244";
            childBorder = "#313244";
          };
          urgent = {
            border = "#f38ba8";
            background = "#1e1e2e";
            text = "#cdd6f4";
            indicator = "#f38ba8";
            childBorder = "#f38ba8";
          };
          background = "#1e1e2e";
        };

        keybindings = lib.mkOptionDefault {
          "${mod}+Tab" = "exec ${rofi} -show window";
          "${mod}+Shift+c" = "exec ${reload_sway}";
          "${mod}+Shift+Escape" =
            "exec swaynag -t warning -m 'Lock system?' -B 'Yes' 'swaylock -f; pkill swaynag'";

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
          "${mod}+n" = "exec ${toggle_slimnotes}";
        };

        # Window commands (for_window rules)
        window.commands = [
          {
            criteria = {
              app_id = "scratchpad_terminal";
            };
            command = "move scratchpad, scratchpad show";
          }
          {
            criteria = {
              app_id = "obsidian";
            };
            command = "move scratchpad, scratchpad show";
          }
          {
            criteria = {
              app_id = "scratchpad_firefox";
            };
            command = "move scratchpad, scratchpad show";
          }
          {
            criteria = {
              app_id = "scratchpad_slimnotes";
            };
            command = "move scratchpad, scratchpad show";
          }
        ];

        menu = "'${rofi} -modi drun,window,run -show drun'";

        # waybar runs as a systemd user service, see waybar.nix
        bars = [ ];

        workspaceOutputAssign = [
          {
            workspace = "1";
            output = "eDP-1";
          }
          {
            workspace = "10";
            output = "HDMI-A-1";
          }
        ];

        gaps = {
          inner = 5;
          outer = 0;
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
            # Store path, so the wallpaper needs no copy in ~/.config
            bg = "${./background.png} center #282828";
          };
          eDP-1 = {
            scale = "1";
          };
        };
      };

      extraConfig = ''
        titlebar_border_thickness 1
        titlebar_padding 5 3
        gaps left 6
        gaps right 6
        gaps bottom 6
        gaps top 1
      '';
    };
}
