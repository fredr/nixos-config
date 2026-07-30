{ pkgs, ... }:
{
  # Same reasoning as the podman group in containers.nix.
  users.users.fredr.extraGroups = [ "libvirtd" ];

  virtualisation = {
    libvirtd = {
      enable = true;
      qemu = {
        package = pkgs.qemu_kvm;
        runAsRoot = true;
        swtpm.enable = true;
        vhostUserPackages = [ pkgs.virtiofsd ];
      };
    };

    # USB passthrough into guests
    spiceUSBRedirection.enable = true;
  };

  services.spice-vdagentd.enable = true;

  # nested virtualization
  boot.extraModprobeConfig = "options kvm_intel nested=1";

  environment.systemPackages = [
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
