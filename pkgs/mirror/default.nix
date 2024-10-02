{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "mirror";
  version = "0.1.0";

  src = fetchFromGitHub {
    owner = "fredr";
    repo = "mirror";
    rev = "f6ac90d9019b30f36d6cde8857dcca4aedbee81d";
    hash = "sha256-t/V/i6+22FvhesBzWC2f00iXzNE1ZcPTbMYEoVQdfKA=";
  };

  vendorHash = null;
}
