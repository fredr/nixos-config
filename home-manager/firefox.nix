{ pkgs, ... }:
let
  catppuccin-mocha-blue = pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
    pname = "catppuccin-mocha-blue";
    version = "2.0";
    addonId = "{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3989617/catppuccin_mocha_blue_git-2.0.xpi";
    sha256 = "0fgl7jcx5h3p5kgp3pcas89s25vjbyx7rzp0hs38s8l0ij6mp0y7";
    meta = { };
  };
in
{
  programs.firefox = {
    enable = true;

    profiles = {
      default = {
        id = 0;
        name = "default";
        isDefault = true;

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          onepassword-password-manager
          catppuccin-mocha-blue
        ];
      };

      scratchpad = {
        id = 1;
        name = "scratchpad";
        isDefault = false;

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          onepassword-password-manager
        ];
      };
    };
  };
  xdg.mimeApps = {
    enable = true;
    associations.added = {
      "image/png" = [ "gimp.desktop" ];
    };
    defaultApplications = {
      "default-web-browser" = [ "firefox.desktop" ];
      "text/html" = [ "firefox.desktop" ];
      "x-scheme-handler/http" = [ "firefox.desktop" ];
      "x-scheme-handler/https" = [ "firefox.desktop" ];
      "x-scheme-handler/about" = [ "firefox.desktop" ];
      "x-scheme-handler/unknown" = [ "firefox.desktop" ];
    };
  };
}
