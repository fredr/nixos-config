{ ... }: {
  # Deduplicate on a timer rather than inline on every store write
  # (auto-optimise-store adds hardlink work to each build).
  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
}
