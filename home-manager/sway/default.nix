{ pkgs, lib, config, ... }: {
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

      # home-manager.useGlobalPkgs is on, so this is the same derivation the
      # NixOS programs.uwsm module installs — no version skew between the two.
      uwsm = "${pkgs.uwsm}/bin/uwsm";

      # Launch an app in its own unit under app-graphical.slice instead of
      # letting processes pile up inside the compositor's unit. A scope (uwsm's
      # default) is forked by the caller, so the app still inherits sway's
      # environment and its journal-connected stdout/stderr — unlike a service,
      # which would start from the user manager's environment and lose anything
      # set inline here (slimnotes below is a service for that reason, and pays
      # for it by declaring its environment explicitly). Passing an absolute path
      # keeps uwsm from resolving the first argument as a Desktop Entry ID; the
      # unit name comes from that path's basename unless given `-a <name>`.
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
      # Unlike the other scratchpads this one runs as a service rather than a
      # scope, because it is the one under active development: an abnormal exit
      # then leaves a failed unit behind (systemctl --user --failed) instead of
      # just a window that silently disappeared. A service starts from the user
      # manager's environment though — uwsm forwards only its own session vars —
      # so the two below have to be declared as unit properties rather than set
      # inline, or the dlopens fail. WAYLAND_DISPLAY and friends are already
      # there, put in by the `uwsm finalize` exec above.
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

      # uwsm owns the session (see programs.uwsm in modules/desktop.nix), so the
      # module's own integration is off: it would start a second, competing
      # sway-session.target that BindsTo graphical-session.target, and its
      # `systemctl --user import-environment` exec is what `uwsm finalize`
      # replaces below.
      systemd.enable = false;

      extraSessionCommands = ''
        # Set SSH_AUTH_SOCK to gnome-keyring's SSH agent socket
        export SSH_AUTH_SOCK="$XDG_RUNTIME_DIR/gcr/ssh"

        # flickering in zed, see https://github.com/swaywm/sway/issues/8755
        export WLR_RENDER_NO_EXPLICIT_SYNC=1
      '';

      wrapperFeatures.gtk = true;

      config = {
        defaultWorkspace = "workspace number 1";

        # uwsm's replacement for the module's `systemctl --user
        # import-environment`: exports WAYLAND_DISPLAY and DISPLAY plus the vars
        # named here into the systemd user environment, then notifies the
        # compositor unit that startup is complete — without this the unit fails
        # on its startup timeout and the session dies. XDG_CURRENT_DESKTOP and
        # XDG_SESSION_TYPE are set by uwsm itself, so only the remainder of what
        # systemd.variables used to carry is listed.
        startup = [
          {
            command = "${uwsm} finalize SWAYSOCK NIXOS_OZONE_WL XCURSOR_THEME XCURSOR_SIZE SSH_AUTH_SOCK PATH XDG_DATA_DIRS XDG_CONFIG_DIRS GIO_EXTRA_MODULES";
          }
        ];

        modifier = mod;
        terminal = "alacritty";

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
