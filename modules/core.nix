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

  # Replaces the drop-in the nixos module writes for the user manager's own root
  # slice. It only wires up memory pressure, so zram could fill to the last page
  # and hand the kill to the kernel instead; and its 80% pressure limit is late
  # enough that the kernel usually wins that race (50% is Fedora's value).
  # Keeping this on the user root slice rather than the system one confines the
  # candidate search to user@$UID.service, so oomd kills the offending app
  # instead of the whole session.
  systemd.user.units."slice".text = lib.mkForce ''
    [Slice]
    ManagedOOMSwap=kill
    ManagedOOMMemoryPressure=kill
    ManagedOOMMemoryPressureLimit=50%
  '';
  systemd.slices.user.sliceConfig.ManagedOOMMemoryPressureLimit = "50%";

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

  services.tailscale = {
    enable = true;
    package = pkgs.tailscale;
  };

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

  # Configure console keymap
  # (the graphical keymap is set per-input in sway, see sway/default.nix)
  console.keyMap = "sv-latin1";

  services.fwupd.enable = true;

  # SSD TRIM - runs weekly for SSD health/performance
  services.fstrim.enable = true;

  # Intel thermal management - prevents throttling
  services.thermald.enable = true;

  programs.zsh.enable = true;
  users.defaultUserShell = pkgs.zsh;

  users.users.fredr = {
    isNormalUser = true;
    description = "fredr";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    packages = [ ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

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
  ];
}
