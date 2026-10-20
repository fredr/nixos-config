{
  stdenv,
  fetchzip,
  autoPatchelfHook,
}:

stdenv.mkDerivation rec {
  pname = "protoc-encore";
  version = "36.1";

  src = fetchzip {
    url = "https://github.com/protocolbuffers/protobuf/releases/download/v${version}/protoc-${version}-linux-x86_64.zip";
    hash = "sha256-7+K5lW33xnypIB+aIx3i32xmoQ/6vktOLT7T2TbIAbc=";
    stripRoot = false;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    cp bin/protoc $out/bin/
    chmod +x $out/bin/protoc

    mkdir -p $out/include
    cp -r include/* $out/include/
  '';

  meta = {
    description = "Protocol Buffers compiler (encore-specific version)";
    platforms = [ "x86_64-linux" ];
  };
}
