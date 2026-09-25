{ pkgs, ... }:
{
  # sway and the apps live in the user manager's units (uwsm, below), so
  # session-N.scope holds only the login shell and the `uwsm start` it waits in.
  # Small, but killing it still tears the session down. Drop-ins on the
  # "session-" prefix apply to every session-N.scope logind creates. These scopes
  # are root-owned and so are the monitored ancestors (-.slice, user.slice), so
  # the xattr is honoured - see the ownership rules in
  # systemd.resource-control(5). Takes effect on next login.
  systemd.units."session-.scope" = {
    overrideStrategy = "asDropin";
    text = ''
      [Scope]
      ManagedOOMPreference=avoid
    '';
  };

  # The compositor's unit, from uwsm. OOMPolicy defaults to "stop", so a kernel
  # OOM kill of any process in this cgroup stops the unit — i.e. the whole
  # session, since sway execs its children. "continue" lets the victim die
  # alone. The preference makes oomd pick app cgroups over the compositor.
  systemd.user.units."wayland-wm@.service" = {
    overrideStrategy = "asDropin";
    text = ''
      [Service]
      OOMPolicy=continue
      ManagedOOMPreference=avoid
    '';
  };

  # No services.xserver here: this is a Wayland-only session. XWayland comes
  # from sway's own wrapper, so X11 clients (steam, xclip) still work.
  #
  # But services.xserver used to pull in services.graphical-desktop, and nothing
  # else in this config sets what that turned on, so all three of these have to
  # be declared explicitly:
  #
  # - hardware.graphics is what creates the /run/opengl-driver symlink. Without
  #   it there is no Mesa EGL/GBM for wlroots to find, so `exec sway` on tty1
  #   dies with a renderer error and drops you straight back to the login
  #   prompt. Not optional.
  # - fonts.enableDefaultPackages, or fonts.packages is empty and you lose
  #   DejaVu, Liberation and the Noto colour emoji font.
  # - systemd.defaultUnit, which graphical-desktop only raises to
  #   graphical.target when a display manager is enabled. Without it the machine
  #   boots to multi-user.target, and `uwsm check may-start` below refuses to
  #   start sway because graphical.target was never reached.
  hardware.graphics.enable = true;
  fonts.enableDefaultPackages = true;
  systemd.defaultUnit = "graphical.target";

  # Start sway on login at the first tty; sway itself is configured in
  # home-manager (home-manager/sway).
  #
  # uwsm runs sway as a `wayland-wm@sway.service` user unit bound into
  # graphical-session.target, which gives the compositor journal-backed
  # stdout/stderr that everything it execs inherits — otherwise an app's crash
  # output goes to the tty and nowhere readable. See
  # `journalctl --user -u wayland-wm@sway.service`.
  #
  # No waylandCompositors entry: it only generates a desktop entry for display
  # managers, and there is none here.
  programs.uwsm.enable = true;

  # may-start checks the VT, login shell, graphical.target, and that no session
  # is running yet; -q keeps other TTYs quiet. `sway` is the home-manager wrapper
  # on PATH, and -F pins its resolved path into the unit, since the user
  # manager's PATH may not find it.
  programs.zsh.loginShellInit = ''
    if uwsm check may-start -q; then
      exec uwsm start -F -- sway
    fi
  '';

  # Enable gnome-keyring for system-wide secret management
  services.gnome.gnome-keyring.enable = true;

  # Enable PAM integration for automatic keyring unlock on login
  security.pam.services.login.enableGnomeKeyring = true;

  # Polkit needed for sway
  # see https://nixos.wiki/wiki/Sway
  security.polkit.enable = true;

  # needed for sway installed via home manager to enable swaylock
  security.pam.services.swaylock = { };

  programs.dconf.enable = true;

  # Enable bluetooth
  hardware.bluetooth.enable = true;
  hardware.bluetooth.powerOnBoot = true;
  services.blueman.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  programs.thunar.enable = true;
  programs.thunar.plugins = with pkgs; [
    thunar-archive-plugin
    thunar-volman
  ];
  services.gvfs.enable = true;

  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-wlr
      pkgs.xdg-desktop-portal-gtk
    ];
    config = {
      common = {
        default = [ "gtk" ];
      };
      sway = {
        default = [
          "wlr"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Screenshot" = [ "wlr" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "wlr" ];
      };
    };
    wlr = {
      enable = true;
      settings = {
        screencast = {
          chooser_type = "simple";
          chooser_cmd = "${pkgs.slurp}/bin/slurp -f 'Monitor: %o' -or";
        };
      };
    };
  };

  # Managed browser policies. The programs.chromium module writes the policy
  # file to Chromium's, Google Chrome's, and Brave's managed-policy paths, so
  # these apply to google-chrome (installed via home-manager) as well.
  programs.chromium = {
    enable = true;
    extraOpts = {
      # Enforce Local Network Access checks so public sites that reach
      # loopback/LAN addresses (e.g. fetch('http://127.0.0.1:8080/')) trigger
      # the permission prompt instead of silently connecting.
      "LocalNetworkAccessRestrictionsEnabled" = true;

      # Force HTTPS everywhere.
      "HttpsOnlyMode" = "force_enabled";

      # Encrypted DNS via Cloudflare, with insecure fallback (keeps Tailscale
      # MagicDNS working: on DoH failure it falls back to the system resolver).
      "DnsOverHttpsMode" = "automatic";
      "DnsOverHttpsTemplates" = "https://cloudflare-dns.com/dns-query";

      # Block third-party cookies.
      "BlockThirdPartyCookies" = true;

      # Post-quantum key agreement for TLS.
      "PostQuantumKeyAgreementEnabled" = true;

      # Kill usage/metrics reporting.
      "MetricsReportingEnabled" = false;

      # Block dangerous/malicious downloads.
      "DownloadRestrictions" = 1;

      # Disable Chrome Remote Desktop firewall traversal.
      "RemoteAccessHostFirewallTraversal" = false;

      # Block geolocation and notifications by default (no prompt spam).
      "DefaultGeolocationSetting" = 2;
      "DefaultNotificationsSetting" = 2;
    };
  };
}
