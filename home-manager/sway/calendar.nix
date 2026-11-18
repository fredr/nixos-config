{ pkgs, lib, ... }:
let
  # Reads the calendars evolution-data-server syncs for the Google accounts
  # added in GNOME Online Accounts (see modules/desktop.nix).
  waybarCalendar = pkgs.writeShellScript "waybar-calendar" ''
    # ECal's typelib pulls in the others, directly or through EDataServer.
    export GI_TYPELIB_PATH=${
      lib.makeSearchPath "lib/girepository-1.0" (
        with pkgs;
        [
          evolution-data-server
          libical
          glib.out
          gobject-introspection
          libsoup_3
          json-glib
        ]
      )
    }
    exec ${
      pkgs.writers.writePython3 "waybar-calendar.py" {
        libraries = [ pkgs.python3Packages.pygobject3 ];
      } (builtins.readFile ./waybar-calendar.py)
    }
  '';
in
{
  # Add Google accounts here; sway has no GNOME Settings to do it from.
  home.packages = [ pkgs.gnome-online-accounts-gtk ];

  programs.waybar.settings.mainBar."custom/calendar" = {
    exec = "${waybarCalendar}";
    return-type = "json";
    format = "󰃰 {}";
    # Empty text means nothing more today.
    hide-empty-text = true;
    on-click = ''${pkgs.xdg-utils}/bin/xdg-open "$(cat "$XDG_RUNTIME_DIR/waybar-calendar-link")"'';
    restart-interval = 30;
  };
}
