{ pkgs, lib, ... }:
let
  uairctl = "${pkgs.uair}/bin/uairctl";

  focus = {
    name = "Focus";
    duration = "25m";
  };
  shortBreak = {
    name = "Break";
    duration = "5m";
  };
  longBreak = {
    name = "Long break";
    duration = "15m";
  };

  # Each update from `uairctl listen` ends in a NUL after the newline, so every
  # line but the first starts with one, and waybar reads lines as C strings:
  # it would see them all as empty. pipefail so a missing daemon is reported
  # as a failure, which blanks the module until restart-interval retries.
  listen = pkgs.writeShellScript "uair-waybar" ''
    set -o pipefail
    ${uairctl} listen -o waybar | ${pkgs.coreutils}/bin/stdbuf -oL ${pkgs.coreutils}/bin/tr -d '\000'
  '';
in
{
  home.packages = [ pkgs.uair ];

  # Holds the timer so waybar (one instance per output) and the keybindings in
  # default.nix all talk to the same one over its socket.
  systemd.user.services.uair = {
    Unit = {
      Description = "Pomodoro timer";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      # Listeners get the time over the socket; without --quiet every tick
      # would also go to the journal.
      ExecStart = "${pkgs.uair}/bin/uair --quiet";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  xdg.configFile."uair/uair.toml" = {
    source = (pkgs.formats.toml { }).generate "uair.toml" {
      loop_on_end = true;

      defaults = {
        # Sessions don't autostart: each one waits, paused, for a toggle.
        command = "${pkgs.libnotify}/bin/notify-send --app-name=uair --urgency=critical \"$name done\" 'Start the next session from the bar or with Super+P'";
        format = "{state} {name} {time}\n";
        time_format = "%M:%S";

        # uair leaves a {...} that isn't one of its specifiers as literal text,
        # so the JSON braces pass through.
        overrides.waybar = {
          format =
            builtins.toJSON {
              text = "{name} {time}";
              alt = "{state}";
              class = "{state}";
              tooltip = "{name}: {time} left of {total}";
            }
            + "\n";
          paused_state_text = "paused";
          resumed_state_text = "running";
        };
      };

      sessions =
        lib.flatten (
          lib.replicate 3 [
            focus
            shortBreak
          ]
        )
        ++ [
          focus
          longBreak
        ];
    };
    # Keeps the current session and remaining time, unlike a restart.
    onChange = "${uairctl} reload || true";
  };

  programs.waybar.settings.mainBar."custom/pomodoro" = {
    exec = "${listen}";
    return-type = "json";
    format = "{icon} {text}";
    format-icons = {
      running = "󰔟";
      paused = "󰏤";
    };
    on-click = "${uairctl} toggle";
    on-click-right = "${uairctl} next";
    # Back to the first focus session, paused. Sessions have no explicit ids,
    # so uair numbers them by position.
    on-click-middle = "${uairctl} jump 0";
    restart-interval = 5;
  };
}
