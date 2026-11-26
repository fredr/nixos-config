{
  lib,
  stdenvNoCC,
  fetchurl,
}:

# The release binary is static-pie, so it runs on NixOS as is. herdr-app
# treats a core under /nix/store as package-managed and never updates it, so
# ./update.sh is how this moves forward.

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "herdr-core";
  version = "0.1.22";

  src = fetchurl {
    url = "https://releases.herdr.dev/core/${finalAttrs.version}/herdr-core-linux-x86_64.tar.gz";
    hash = "sha256-MFTsOZLOgMVxXXIcqp3O+mBWch0V3BE/R1CvznY7pd8=";
  };

  sourceRoot = ".";

  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-core $out/bin/herdr-core
    ln -s herdr-core $out/bin/hc
    runHook postInstall
  '';

  meta = {
    description = "Terminals for coding agents, the runtime behind the Herdr app";
    homepage = "https://github.com/herdrdev/herdr-core";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "hc";
  };
})
