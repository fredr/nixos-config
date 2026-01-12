{ stdenv, fetchzip, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "protoc-gen-go-grpc-encore";
  version = "1.5.1";

  src = fetchzip {
    url = "https://github.com/grpc/grpc-go/releases/download/cmd%2Fprotoc-gen-go-grpc%2Fv${version}/protoc-gen-go-grpc.v${version}.linux.amd64.tar.gz";
    hash = "sha256-3h8LtgW1qi43a9gs4t4ZTXh4/YB3ZKuSKU4RqbKLVsA=";
    stripRoot = false;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    cp protoc-gen-go-grpc $out/bin/
    chmod +x $out/bin/protoc-gen-go-grpc
  '';

  meta = {
    description = "Go gRPC code generator for Protocol Buffers (encore-specific version)";
    platforms = [ "x86_64-linux" ];
  };
}
