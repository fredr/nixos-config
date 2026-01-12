{ stdenv, fetchzip, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "sqlc-encore";
  version = "1.25.0";

  src = fetchzip {
    url = "https://github.com/sqlc-dev/sqlc/releases/download/v${version}/sqlc_${version}_linux_amd64.tar.gz";
    hash = "sha256-DXhJOfubYzDystCU1KgnHNX0CZAphg0Zd31t6ooU4uU=";
    stripRoot = false;
  };

  nativeBuildInputs = [ autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    cp sqlc $out/bin/
    chmod +x $out/bin/sqlc
  '';

  meta = {
    description = "SQL compiler (encore-specific version)";
    platforms = [ "x86_64-linux" ];
  };
}
