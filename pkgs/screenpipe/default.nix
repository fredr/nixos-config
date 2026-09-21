{
  lib,
  stdenv,
  fetchurl,
  makeBinaryWrapper,
  autoPatchelfHook,
  dbus,
  libgbm,
  libpulseaudio,
  openblas,
  openssl,
  pipewire,
  wayland,
  xorg,
  xz,
  bun,
  ffmpeg-headless,
  grim,
}:

# nixpkgs' own `screen-pipe` is v0.1.48 (from louis030195/screen-pipe) and has
# been marked broken since it stopped building on Hydra; upstream has moved to
# screenpipe/screenpipe and is on 0.4.x. Upstream ships no Linux release assets
# on GitHub ("build from source"), but the npm CLI does: the platform package
# @screenpipe/cli-linux-x64 carries the recorder engine plus a statically linked
# tesseract and english traineddata.
#
# check https://registry.npmjs.org/screenpipe/latest
let
  version = "0.4.50";
in
stdenv.mkDerivation {
  pname = "screenpipe";
  inherit version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@screenpipe/cli-linux-x64/-/cli-linux-x64-${version}.tgz";
    hash = "sha256-rFz1FvIbcKVB1Y/85wohH0yIw9tHepo9p4jgMqZOIYI=";
  };

  nativeBuildInputs = [
    makeBinaryWrapper
    autoPatchelfHook
  ];

  buildInputs = [
    dbus
    libgbm
    libpulseaudio
    openblas
    openssl
    pipewire
    stdenv.cc.cc.lib
    wayland
    xorg.libxcb
    xz
  ];

  dontBuild = true;

  # The engine looks for tesseract next to its own executable, so keep
  # upstream's bin/ layout in libexec and wrap it from $out/bin.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/libexec/screenpipe
    cp -r bin/. $out/libexec/screenpipe/
    chmod +x $out/libexec/screenpipe/screenpipe $out/libexec/screenpipe/tesseract

    makeBinaryWrapper $out/libexec/screenpipe/screenpipe $out/bin/screenpipe \
      --set SCREENPIPE_NO_UPDATE_CHECK 1 \
      --set SCREENPIPE_DISABLE_TELEMETRY 1 \
      --set TESSDATA_PREFIX $out/libexec/screenpipe/tessdata \
      --prefix PATH : ${
        lib.makeBinPath [
          # ffmpeg-sidecar downloads a static ffmpeg tarball when it finds none
          ffmpeg-headless
          # wlroots screen capture path
          grim
          # pipes and the bundled agents shell out to bun
          bun
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Local-first screen and audio recorder with search (screenpipe CLI)";
    homepage = "https://github.com/screenpipe/screenpipe";
    # Screenpipe Commercial License: free for personal/non-commercial use,
    # 7-day evaluation for business use.
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "screenpipe";
  };
}
