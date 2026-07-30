{ ... }:
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix

    ../../modules/core.nix
    ../../modules/desktop.nix
    ../../modules/printing.nix
    ../../modules/containers.nix
    ../../modules/vms.nix
    # ../../modules/gaming.nix
  ];

  system.stateVersion = "25.11";
}
