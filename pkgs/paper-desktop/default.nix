{
  lib,
  appimageTools,
  fetchurl,
  makeWrapper,
}:

# download.paper.design only serves the latest build and ignores any version
# in the URL, so the hash breaks on every upstream release. ./update.sh reads
# the version from the Content-Disposition header and re-pins both.

let
  pname = "paper-desktop";
  version = "0.5.19";
  hash = "0jz0bar790ypmvngml3i0zcikc6i6r38rkxj8h09y207fri599k0";

  src = fetchurl {
    url = "https://download.paper.design/linux/appImage/x64";
    name = "${pname}-${version}.AppImage";
    sha256 = hash;
  };

  appimageContents = appimageTools.extract { inherit pname version src; };
in
appimageTools.wrapType2 {
  inherit pname version src;

  nativeBuildInputs = [ makeWrapper ];

  extraInstallCommands = ''
    # Same Wayland opt-in that nixpkgs' Electron apps honour.
    wrapProgram $out/bin/${pname} \
      --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations --enable-wayland-ime=true}}"

    install -Dm444 ${appimageContents}/${pname}.desktop -t $out/share/applications
    substituteInPlace $out/share/applications/${pname}.desktop \
      --replace-fail 'Exec=AppRun --no-sandbox' 'Exec=${pname}'
    cp -r ${appimageContents}/usr/share/icons $out/share
  '';

  meta = {
    description = "Paper - design canvas built on web standards";
    homepage = "https://paper.design";
    license = lib.licenses.unfree;
    sourceProvenance = [ lib.sourceTypes.binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = pname;
  };
}
