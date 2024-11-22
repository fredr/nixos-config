{ ... }: {
  services.kanshi = {
    enable = true;

    settings = [
      {
        profile = {
          name = "none";

          outputs = [
            {
              criteria = "eDP-1";
              position = "0,0";
              mode = "1920x1200@60.001Hz";
              status = "enable";
            }
          ];
        };
      }
      {
        profile = {
          name = "home";

          outputs = [
            {
              criteria = "eDP-1";
              position = "740,1440";
              mode = "1920x1200@60.001Hz";
              status = "enable";
            }
            {
              criteria = "ASUSTek COMPUTER INC VG34VQL3A S2LMDW006571";
              position = "0,0";
              mode = "3440x1440@59.973Hz";
              status = "enable";
            }
          ];
        };
      }
    ];
  };
}


