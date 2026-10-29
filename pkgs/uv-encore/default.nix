{
  stdenv,
  fetchzip,
  autoPatchelfHook,
}:

# Matches the uv_build pin in encore's sdk/py/infra/pyproject.toml. uv only uses
# its built-in build backend when its own version satisfies that pin; otherwise
# it downloads the uv_build wheel, whose prebuilt binary can't run on NixOS.
stdenv.mkDerivation rec {
  pname = "uv-encore";
  version = "0.12.10";

  src = fetchzip {
    url = "https://github.com/astral-sh/uv/releases/download/${version}/uv-x86_64-unknown-linux-gnu.tar.gz";
    hash = "sha256-aXS2zTUWxKbgQmO96mHEn0ZqQaYlV05+NnLOoFttZRg=";
  };

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [ stdenv.cc.cc.lib ];

  installPhase = ''
    mkdir -p $out/bin
    cp uv uvx $out/bin/
    chmod +x $out/bin/uv $out/bin/uvx
  '';

  meta = {
    description = "Python package manager (encore-specific version)";
    platforms = [ "x86_64-linux" ];
  };
}
