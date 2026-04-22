{ lib, stdenv, fetchurl, makeBinaryWrapper, autoPatchelfHook, procps, ripgrep, bubblewrap, socat }:

# check https://downloads.claude.ai/claude-code-releases/latest
# nix-prefetch-url https://downloads.claude.ai/claude-code-releases/<VERSION>/linux-x64/claude

let
  version = "2.1.117";
  platform = "linux-x64";
  hash = "1zm5anh1797j7r1x594h1s1a8wrpyn2ph7iyki1wwbp3v5inj95p";
in
stdenv.mkDerivation {
  pname = "claude-code";
  inherit version;

  src = fetchurl {
    url = "https://downloads.claude.ai/claude-code-releases/${version}/${platform}/claude";
    sha256 = hash;
  };

  dontUnpack = true;
  dontStrip = true; # stripping corrupts the embedded Bun trailer

  nativeBuildInputs = [ makeBinaryWrapper autoPatchelfHook ];

  installPhase = ''
    mkdir -p $out/bin
    install -m755 $src $out/bin/.claude-unwrapped
    makeBinaryWrapper $out/bin/.claude-unwrapped $out/bin/claude \
      --set DISABLE_AUTOUPDATER 1 \
      --set DISABLE_INSTALLATION_CHECKS 1 \
      --set USE_BUILTIN_RIPGREP 0 \
      --prefix PATH : ${lib.makeBinPath [ procps ripgrep bubblewrap socat ]}
  '';

  meta = {
    description = "Claude Code - AI coding assistant in your terminal";
    homepage = "https://www.anthropic.com/claude-code";
    license = lib.licenses.unfree;
    platforms = [ "x86_64-linux" ];
    mainProgram = "claude";
  };
}
