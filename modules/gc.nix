{ config, pkgs, ... }: {
  # Deduplicate on a timer rather than inline on every store write
  # (auto-optimise-store adds hardlink work to each build).
  nix.optimise.automatic = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # Cargo never garbage-collects target/: every Cargo.lock, feature or flag
  # change leaves the old artifacts behind. Piggyback on the store GC.
  # --time drops artifacts unused for two weeks; --maxsize caps busy
  # worktrees that bloat within days (one hit 331G in nine).
  systemd.services.cargo-sweep = {
    description = "Sweep stale Cargo build artifacts";
    wantedBy = [ "nix-gc.service" ];
    after = [ "nix-gc.service" ];
    path = [ pkgs.cargo pkgs.cargo-sweep ];
    # cargo-sweep shells out to `cargo metadata`, which must not hit the network.
    environment.CARGO_NET_OFFLINE = "true";
    serviceConfig = {
      Type = "oneshot";
      User = "fredr";
    };
    script = ''
      cargo-sweep sweep --recursive --time 14 ${config.users.users.fredr.home}/projects
      cargo-sweep sweep --recursive --maxsize 30GB ${config.users.users.fredr.home}/projects
    '';
  };
}
