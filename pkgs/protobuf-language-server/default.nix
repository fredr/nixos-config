{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "protobuf-language-server";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "lasorda";
    repo = "protobuf-language-server";
    rev = "6e366e0b805480cf319c6e6ee12d0d1292369556";
    hash = "sha256-95CR1m3Ydul8WF4N12JFFqmva2vltGb6vtrUu7uck4E=";
  };

  vendorHash = "sha256-4nTpKBe7ekJsfQf+P6edT/9Vp2SBYbKz1ITawD3bhkI=";

  subPackages = [ "." ];
}
