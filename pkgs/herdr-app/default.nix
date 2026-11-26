{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
  makeWrapper,
  makeDesktopItem,
  copyDesktopItems,
  libxcb,
  libxkbcommon,
  libGL,
  vulkan-loader,
  wayland,
  herdr-core,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "herdr-app";
  version = "0.1.18";

  src = fetchurl {
    url = "https://releases.herdr.dev/app/${finalAttrs.version}/herdr-app-linux-x86_64.tar.gz";
    hash = "sha256-ihHt153UCzSfcobPUZELYuIRNtr48DAFqf0sTcWDD4M=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    copyDesktopItems
  ];

  buildInputs = [
    (lib.getLib stdenv.cc.cc)
    libxcb
    libxkbcommon
  ];

  # dlopen()ed at startup, so autoPatchelf can't see them in DT_NEEDED.
  runtimeDependencies = [
    libGL
    libxkbcommon
    vulkan-loader
    wayland
  ];

  # The app self-updates only when herdr-app.svg sits beside its binary, so
  # keeping the icon out of libexec stops it from trying to rewrite the store.
  installPhase = ''
    runHook preInstall
    install -Dm755 herdr-app $out/libexec/herdr-app/herdr-app
    install -Dm444 herdr-app.svg $out/share/icons/hicolor/scalable/apps/herdr-app.svg
    makeWrapper $out/libexec/herdr-app/herdr-app $out/bin/herdr-app \
      --suffix PATH : ${lib.makeBinPath [ herdr-core ]} \
      --set HERDR_TELEMETRY 0
    runHook postInstall
  '';

  desktopItems = [
    (makeDesktopItem {
      name = "herdr-app";
      desktopName = "Herdr";
      comment = "Terminals and coding agents that keep running";
      exec = "herdr-app";
      icon = "herdr-app";
      categories = [ "Development" ];
      startupWMClass = "herdr-app";
    })
  ];

  meta = {
    description = "Desktop app for terminals and coding agents";
    homepage = "https://herdr.dev";
    license = lib.licenses.asl20;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "herdr-app";
  };
})
