{ pkgs, inputs, ... }:
let
  airbat = inputs.airbat.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  # `airbat` in a terminal prints the levels too, read from the daemon.
  home.packages = [ airbat ];

  # AirPods accept one battery session per host, so a single daemon owns it
  # and every waybar instance (one per output) reads from its socket.
  systemd.user.services.airbat = {
    Unit = {
      Description = "AirPods battery daemon";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${airbat}/bin/airbat daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };

  programs.waybar.settings.mainBar."custom/airbat" = {
    exec = "${airbat}/bin/airbat waybar";
    return-type = "json";
    format = "󰋋 {}";
    # Empty text means no AirPods are connected.
    hide-empty-text = true;
    restart-interval = 5;
  };
}
