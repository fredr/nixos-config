{ pkgs, lib, ... }:
let
  chrome = lib.getExe' pkgs.google-chrome "google-chrome-stable";

  # One launcher per profile. Picking a profile in Chrome's profile picker
  # hands off to that profile's existing window (as a new tab) and closes the
  # picker; an explicit --profile-directory skips the picker and always gets a
  # new window, even when Chrome is already running.
  mkProfile = name: dir: {
    name = "Chrome (${name})";
    genericName = "Web Browser";
    # Quoted as a whole argument, as the desktop entry spec requires.
    exec = ''${chrome} "--profile-directory=${dir}" --new-window'';
    icon = "google-chrome";
    categories = [
      "Network"
      "WebBrowser"
    ];
    settings.StartupWMClass = "google-chrome";
  };
in
{
  home.packages = [ pkgs.google-chrome ];

  # Directory names are the keys of profile.info_cache in
  # ~/.config/google-chrome/Local State.
  xdg.desktopEntries = {
    chrome-encore = mkProfile "encore.dev" "Default";
    chrome-personal = mkProfile "Personal" "Profile 1";
  };
}
