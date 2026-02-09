{ pkgs, host, lib, ... }:
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

  # Userspace OOM killer - acts before system becomes unresponsive
  systemd.oomd = {
    enable = true;
    enableRootSlice = true;
    enableSystemSlice = true;
    enableUserSlices = true;
  };

  # Enable flakes
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  networking.hostName = host.hostname;

  # Enable networking
  networking.networkmanager.enable = true;

  # Firewall
  networking.firewall.enable = true;
  # networking.firewall.allowedTCPPorts = [ 1111 ];

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

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.displayManager.startx.enable = true;

  # Enable gnome-keyring for system-wide secret management
  services.gnome.gnome-keyring.enable = true;

  # Enable PAM integration for automatic keyring unlock on login
  security.pam.services.login.enableGnomeKeyring = true;

  # Polkit needed for sway
  # see https://nixos.wiki/wiki/Sway
  security.polkit.enable = true;

  # needed for sway installed via home manager to enable swaylock
  security.pam.services.swaylock = { };

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "se";
    variant = "";
  };

  # Configure console keymap
  console.keyMap = "sv-latin1";

  # Enable CUPS to print documents.
  services.printing.enable = true;

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
        default = [ "wlr" "gtk" ];
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
    extraGroups = [ "networkmanager" "wheel" "podman" "libvirtd" ];
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

  users.extraGroups.vboxusers.members = [ "fredr" ];

  system.activationScripts.report-changes = {
    text = ''
      PATH=$PATH:${lib.makeBinPath [pkgs.nix pkgs.nvd]}
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
