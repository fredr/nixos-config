{ stdenv, fetchzip, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "protoc-gen-go-encore";
  version = "1.36.10";

  src = fetchzip {
    url = "https://github.com/protocolbuffers/protobuf-go/releases/download/v${version}/protoc-gen-go.v${version}.linux.amd64.tar.gz";
    hash = "sha256-EbK/W8Y4H1JJ5HjGJuzvhFBfxmhAX3fKXmmdI7VzUeI=";
    stripRoot = false;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    cp protoc-gen-go $out/bin/
    chmod +x $out/bin/protoc-gen-go
  '';

  meta = {
    description = "Go code generator for Protocol Buffers (encore-specific version)";
    platforms = [ "x86_64-linux" ];
  };
}
