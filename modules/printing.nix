{ pkgs, ... }:
{
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

  # Needed to resolve the printer's dnssd:// URI above; also gives general
  # .local name resolution.
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };
}
