{ pkgs, ... }: {

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
