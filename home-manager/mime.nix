{ ... }:
{
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
      # zathura-cb also claims inode/directory, so be explicit.
      "inode/directory" = [ "thunar.desktop" ];
    };
  };
}
