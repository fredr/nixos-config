{
  pkgs,
  host,
  lib,
  inputs,
  ...
}:
{
  imports = [
    ./gc.nix
  ];

  boot.kernelPackages = pkgs.linuxPackages_latest;

  boot.kernel.sysctl = {
    "kernel.yama.ptrace_scope" = 0;
    # Memory management tuning for zram
    "vm.swappiness" = 180;
    "vm.watermark_boost_factor" = 0;
    "vm.watermark_scale_factor" = 125;
    "vm.page-cluster" = 0;
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Compressed swap in RAM
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Userspace OOM killer - acts before system becomes unresponsive.
  # Root + user slices only, matching Fedora: monitoring system.slice
  # lets oomd kill NetworkManager/dbus/podman, which is worse than the
  # pressure it relieves.
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableUserSlices = true;
  };

  # sway is launched from the tty login shell, so it lives in a logind session
  # scope (/user.slice/user-1000.slice/session-N.scope) along with every GUI app
  # started from it. That makes the scope by far the largest reclaim candidate
  # under user.slice, i.e. oomd's first pick would be the entire desktop.
  # Drop-ins on the "session-" prefix apply to every session-N.scope logind
  # creates. These scopes are root-owned and so are the monitored ancestors
  # (-.slice, user.slice), so the xattr is honoured - see the ownership rules in
  # systemd.resource-control(5). Takes effect on next login.
  systemd.units."session-.scope" = {
    overrideStrategy = "asDropin";
    text = ''
      [Scope]
      ManagedOOMPreference=avoid
    '';
  };

  # Enable flakes
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Point the CLI at the same nixpkgs the system is built from, so
  # `nix shell nixpkgs#foo` and `<nixpkgs>` resolve to the locked input
  # instead of fetching a separate copy.
  nix.registry.nixpkgs.flake = inputs.nixpkgs;
  nix.nixPath = [ "nixpkgs=${inputs.nixpkgs}" ];

  networking.hostName = host.hostname;

  # Enable networking
  networking.networkmanager.enable = true;

  # Firewall
  networking.firewall.enable = true;

  # nftables
  networking.nftables.enable = true;

  # Set your time zone.
  time.timeZone = "Europe/Stockholm";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "sv_SE.UTF-8";
    LC_IDENTIFICATION = "sv_SE.UTF-8";
    LC_MEASUREMENT = "sv_SE.UTF-8";
    LC_MONETARY = "sv_SE.UTF-8";
    LC_NAME = "sv_SE.UTF-8";
    LC_NUMERIC = "sv_SE.UTF-8";
    LC_PAPER = "sv_SE.UTF-8";
    LC_TELEPHONE = "sv_SE.UTF-8";
    LC_TIME = "sv_SE.UTF-8";
  };

  services.fwupd.enable = true;

  # SSD TRIM - runs weekly for SSD health/performance
  services.fstrim.enable = true;

  # Intel thermal management - prevents throttling
  services.thermald.enable = true;

  fonts.enableDefaultPackages = true;

  # Enable gnome-keyring for system-wide secret management
  services.gnome.gnome-keyring.enable = true;

  # Enable PAM integration for automatic keyring unlock on login
  security.pam.services.login.enableGnomeKeyring = true;

  # Polkit needed for sway
  # see https://nixos.wiki/wiki/Sway
  security.polkit.enable = true;

  # needed for sway installed via home manager to enable swaylock
  security.pam.services.swaylock = { };

  # Configure console keymap
  # (the graphical keymap is set per-input in sway, see sway/default.nix)
  console.keyMap = "sv-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;
  services.printing.drivers = [ pkgs.samsung-unified-linux-driver ];

  # Define the printer declaratively. The `ensure-printers` service re-runs
  # `lpadmin` on every activation, which re-copies the PPD with the current
  # driver store path. This prevents the queue from breaking after updates,
  # which happened because the PPD copied into /etc/cups/ppd hard-codes the
  # absolute /nix/store path of the pstospl filter.
  hardware.printers.ensurePrinters = [
    {
      name = "Samsung_SCX-3200_Series_";
      deviceUri = "dnssd://Samsung%20SCX-3200%20Series%20(SEC001599722880)._printer._tcp.local/";
      model = "samsung/SCX-3200.ppd";
    }
  ];

  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

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
  programs.thunar.plugins = with pkgs.xfce; [
    thunar-archive-plugin
    thunar-volman
  ];
  services.gvfs.enable = true;

  programs.zsh.enable = true;
  programs.zsh.loginShellInit = ''
    [ "$(tty)" = "/dev/tty1" ] && exec sway
  '';
  users.defaultUserShell = pkgs.zsh;

  programs.steam.enable = true;

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

  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
  };

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

  users.users.fredr = {
    isNormalUser = true;
    description = "fredr";
    extraGroups = [
      "networkmanager"
      "wheel"
      "podman"
      "libvirtd"
    ];
    packages = [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  virtualisation = {
    containers.enable = true;
    podman = {
      enable = true;

      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;

      # Required for containers under podman-compose to be able to talk to each other.
      defaultNetwork.settings.dns_enabled = true;
    };

    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };

    spiceUSBRedirection.enable = true;
  };

  services.spice-vdagentd.enable = true;

  programs.dconf.enable = true;

  # nested virtualization
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  system.activationScripts.report-changes = {
    text = ''
      PATH=$PATH:${
        lib.makeBinPath [
          pkgs.nix
          pkgs.nvd
        ]
      }
      ${lib.getExe pkgs.nvd} diff $(ls -d /nix/var/nix/profiles/system-*-link | tail -n 2) || true
    '';
    supportsDryActivation = true;
  };

  environment.systemPackages = [
    pkgs.cifs-utils
    pkgs.ntfs3g
    pkgs.ms-sys
    pkgs.virt-manager
    pkgs.virt-viewer
    pkgs.spice
    pkgs.spice-gtk
    pkgs.spice-protocol
    pkgs.virtio-win
    pkgs.win-spice
    pkgs.swtpm
  ];
}
