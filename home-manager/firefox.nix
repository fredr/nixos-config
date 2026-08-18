{ pkgs, ... }:
let
  catppuccin-mocha-blue = pkgs.nur.repos.rycee.firefox-addons.buildFirefoxXpiAddon {
    pname = "catppuccin-mocha-blue";
    version = "2.0";
    addonId = "{2adf0361-e6d8-4b74-b3bc-3f450e8ebb69}";
    url = "https://addons.mozilla.org/firefox/downloads/file/3989617/catppuccin_mocha_blue_git-2.0.xpi";
    sha256 = "0fgl7jcx5h3p5kgp3pcas89s25vjbyx7rzp0hs38s8l0ij6mp0y7";
    meta = { };
  };
in
{
  programs.firefox = {
    enable = true;

    policies = {
      # Gate local network / loopback access (e.g. a public site doing
      # fetch('http://127.0.0.1:8080/')) behind a user permission prompt.
      LocalNetworkAccess = {
        Enabled = true;
        EnablePrompting = true;
        BlockTrackers = true;
      };

      # Force HTTPS everywhere.
      HttpsOnlyMode = "force_enabled";

      # Encrypted DNS via Cloudflare. Mode is DoH-with-fallback, and ts.net is
      # excluded so Tailscale MagicDNS names keep resolving via the system.
      DNSOverHTTPS = {
        Enabled = true;
        ProviderURL = "https://mozilla.cloudflare-dns.com/dns-query";
        Locked = false;
        ExcludedDomains = [ "ts.net" ];
      };

      # Reject tracker + third-party cookies (partition the rest).
      Cookies = {
        Behavior = "reject-tracker-and-partition-foreign";
      };

      # Strict tracking protection incl. crypto-mining and fingerprinting.
      EnableTrackingProtection = {
        Value = true;
        Cryptomining = true;
        Fingerprinting = true;
      };

      # Post-quantum key agreement for TLS.
      PostQuantumKeyAgreementEnabled = true;

      # Kill telemetry / studies.
      DisableTelemetry = true;
      DisableFirefoxStudies = true;

      # Reduce background chatter / stored history.
      NetworkPrediction = false;
      DisableFormHistory = true;
      SearchSuggestEnabled = false;
    };

    profiles = {
      default = {
        id = 0;
        name = "default";
        isDefault = true;

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          onepassword-password-manager
          catppuccin-mocha-blue
        ];
      };

      scratchpad = {
        id = 1;
        name = "scratchpad";
        isDefault = false;

        extensions.packages = with pkgs.nur.repos.rycee.firefox-addons; [
          ublock-origin
          onepassword-password-manager
        ];
      };
    };
  };
}
