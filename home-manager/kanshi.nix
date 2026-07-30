{ pkgs, ... }:
let
  # Outputs are destroyed and re-created across suspend/resume, which leaves
  # waybar's sway/workspaces module empty (Alexays/Waybar#3163). kanshi
  # re-applies a profile once the outputs have settled, so that is the right
  # moment to rebuild the bar.
  restartWaybar = "${pkgs.systemd}/bin/systemctl --user restart waybar.service";
in
{
  services.kanshi = {
    enable = true;

    settings = [
      {
        profile = {
          name = "none";

          exec = [ restartWaybar ];

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

          exec = [ restartWaybar ];

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
