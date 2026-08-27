{ pkgs, ... }:
{
  # sway runs under uwsm (see programs.uwsm below), so the compositor and the
  # apps live in the user manager's units, not in the logind session scope. What
  # is left in /user.slice/user-1000.slice/session-N.scope is the login shell and
  # the `uwsm start` process it waits in — small, but killing it still tears the
  # whole session down, so it stays off oomd's list. Drop-ins on the "session-"
  # prefix apply to every session-N.scope logind creates. These scopes are
  # root-owned and so are the monitored ancestors (-.slice, user.slice), so the
  # xattr is honoured - see the ownership rules in systemd.resource-control(5).
  # Takes effect on next login.
  systemd.units."session-.scope" = {
    overrideStrategy = "asDropin";
    text = ''
      [Scope]
      ManagedOOMPreference=avoid
    '';
  };

  # No services.xserver here: this is a Wayland-only session. XWayland comes
  # from sway's own wrapper, so X11 clients (steam, xclip) still work.
  #
  # But services.xserver used to pull in services.graphical-desktop, and nothing
  # else in this config sets what that turned on, so both of these have to be
  # declared explicitly:
  #
  # - hardware.graphics is what creates the /run/opengl-driver symlink. Without
  #   it there is no Mesa EGL/GBM for wlroots to find, so `exec sway` on tty1
  #   dies with a renderer error and drops you straight back to the login
  #   prompt. Not optional.
  # - fonts.enableDefaultPackages, or fonts.packages is empty and you lose
  #   DejaVu, Liberation and the Noto colour emoji font.
  hardware.graphics.enable = true;
  fonts.enableDefaultPackages = true;

  # Start sway on login at the first tty; sway itself is configured in
  # home-manager (home-manager/sway).
  #
  # uwsm wraps the compositor in a `wayland-wm@sway.service` user unit and binds
  # it into graphical-session.target. Two consequences worth the indirection:
  #
  # - The unit's stdout/stderr are the journal, and everything sway execs
  #   inherits those fds. Before this sway inherited the tty, so a crashing app
  #   wrote its panic to /dev/tty1 and nowhere else — unreadable after the fact.
  #   Now: journalctl --user -u wayland-wm@sway.service
  # - graphical-session.target is actually reached, so user services bind to it
  #   directly instead of needing sway to start a sway-session.target of its own.
  #
  # No programs.uwsm.waylandCompositors entry: that option only generates a
  # wayland-sessions desktop entry for display managers, and there is none here.
  # The module also switches services.dbus.implementation to "broker", which this
  # config was already using.
  programs.uwsm.enable = true;

  # `uwsm check may-start` replaces the old `[ "$(tty)" = /dev/tty1 ]` test: it
  # checks the VT (1 unless given others), that this is a login shell, that the
  # system reached graphical.target, and that no graphical session is active yet.
  # -q keeps logins on other TTYs quiet. `sway` resolves off PATH to the
  # home-manager wrapper, so extraSessionCommands and wrapperFeatures still
  # apply; -F hardcodes the resolved path into the generated unit.
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
