{ stdenv, fetchzip, autoPatchelfHook }:

stdenv.mkDerivation rec {
  pname = "sqlc-encore";
  version = "1.30.0";

  src = fetchzip {
    url = "https://github.com/sqlc-dev/sqlc/releases/download/v${version}/sqlc_${version}_linux_amd64.tar.gz";
    hash = "sha256-iXTjHAx+W0Afw6xjz8CgGaE269ZpW6PBgrDkOe/3lb4=";
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
