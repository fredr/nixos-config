{ pkgs, ... }: {
  programs.waybar = {
    enable = true;
    package = pkgs.waybar;

    settings = {
      mainBar = {
        layer = "top";
	position = "top";
	height = 30;
	spacing = 4;
	modules-left = [ "sway/workspaces" "sway/mode" "sway/scratchpad" ];
	modules-center = [ "sway/window" ];
	modules-right = [ "idle_inhibitor" "custom/k8s" "network" "cpu" "memory" "backlight" "sway/language" "battery" "battery#bat2" "clock" "tray" ];

       "sway/mode" = {
           format = "<span style=\"italic\">{}</span>";
       };
       "sway/scratchpad" = {
           format = "{icon} {count}";
           show-empty = false;
           format-icons = ["" ""];
           tooltip = true;
           tooltip-format = "{app}: {title}";
       };
       idle_inhibitor = {
           format = "{icon}";
           format-icons = {
               activated = "";
               deactivated = "";
           };
       };
       "tray" = {
           icon-size = 21;
           spacing = 10;
       };
       "clock" = {
           tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
           format-alt = "{:%Y-%m-%d}";
       };
       "cpu" = {
           format = "{usage}% ";
           tooltip = false;
       };
       "memory" = {
           format = "{}% ";
       };
       "backlight" = {
           format = "{icon}";
           format-icons = ["" "" "" "" "" "" "" "" ""];
       };
       "battery" = {
           states = {
               good = 95;
               warning = 30;
               critical = 15;
           };
           format = "{capacity}% {icon}";
           format-charging = "{capacity}% ";
           format-plugged = "{capacity}% ";
           format-alt = "{time} {icon}";
           format-good = ""; # An empty format will hide the module
           format-full = "";
           format-icons = ["" "" "" "" ""];
       };
       "battery#bat2" = {
           bat = "BAT2";
       };
       "network" = {
           format-wifi = "";
           tooltip-format-wifi = "{essid} ({signalStrength}%) ";
           format-ethernet = "{ipaddr}/{cidr} ";
           tooltip-format = "{ifname} via {gwaddr} ";
           format-linked = "{ifname} (No IP) ";
           format-disconnected = "Disconnected ⚠";
           format-alt = "{ifname}: {ipaddr}/{cidr}";
       };
       "custom/k8s" = {
           format = "☁️ {}";
	   exec = pkgs.writeShellScript "current context" ''
	     ${pkgs.kubectl}/bin/kubectl config current-context
	   '';
           interval = 5;
	   on-click = pkgs.writeShellScript "choose context" ''
	     ${pkgs.kubectx}/bin/kubectx $(${pkgs.kubectx}/bin/kubectx | ${pkgs.rofi}/bin/rofi -dmenu -p 'Context')
	   '';
       };
      };
    };
    style = ./waybar.css;
  };

}
