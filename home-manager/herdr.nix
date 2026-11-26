{ config, pkgs, ... }:
let
  alacritty = config.programs.alacritty.settings;
  ansiOrder = [
    "black"
    "red"
    "green"
    "yellow"
    "blue"
    "magenta"
    "cyan"
    "white"
  ];

  managedSettings = pkgs.writeText "herdr-app-managed.json" (
    builtins.toJSON {
      theme = "alacritty";
      font = alacritty.font.normal.family;
      # Alacritty sizes in points, herdr-app in px.
      font_size = alacritty.font.size * 4 / 3;
      # herdr-app defaults to Medium; Alacritty uses Regular.
      font_weight = 400;
    }
  );
in
{
  # herdr (the TUI) and herdr-app are separate programs: the app runs its
  # terminals in herdr-core (`hc`), not in the TUI's server.
  home.packages = [
    pkgs.unstable.herdr
    pkgs.mypkgs.herdr-core
    pkgs.mypkgs.herdr-app
  ];

  xdg.configFile."herdr-app/themes/alacritty.json".text = builtins.toJSON {
    background = alacritty.colors.primary.background;
    foreground = alacritty.colors.primary.foreground;
    cursor = alacritty.colors.cursor.cursor;
    # Alacritty pairs its light selection with dark text, but herdr-app themes
    # can't set a selection text color, so use one that keeps text readable.
    selection = "#585b70";
    ansi =
      map (name: alacritty.colors.normal.${name}) ansiOrder
      ++ map (name: alacritty.colors.bright.${name}) ansiOrder;
  };

  # herdr-app writes settings.json at runtime (zoom, theme picker, Settings),
  # so merge the managed keys in rather than linking a read-only file.
  home.activation.herdrAppSettings = config.lib.dag.entryAfter [ "linkGeneration" ] ''
    settings="$HOME/.config/herdr-app/settings.json"
    run mkdir -p "$(dirname "$settings")"
    existing='{}'
    if [ -e "$settings" ]; then
      existing="$(cat "$settings")"
    fi
    merged="$(echo "$existing" | ${pkgs.jq}/bin/jq --slurpfile m ${managedSettings} '. * $m[0]')"
    if [ -z "''${DRY_RUN:-}" ]; then
      echo "$merged" > "$settings"
    fi
  '';
}
