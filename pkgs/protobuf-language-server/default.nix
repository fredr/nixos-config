{ buildGoModule, fetchFromGitHub }:

buildGoModule {
  pname = "protobuf-language-server";
  version = "0.1.1";

  src = fetchFromGitHub {
    owner = "lasorda";
    repo = "protobuf-language-server";
    rev = "6e366e0b805480cf319c6e6ee12d0d1292369556";
    hash = "sha256-bDsvByXa2kH3DnvQpAq79XvwFg4gfhtOP2BpqA1LCI0=";
  };

  vendorHash = "sha256-dRria1zm5Jk7ScXh0HXeU686EmZcRrz5ZgnF0ca9aUQ=";

  subPackages = [ "." ];
}
