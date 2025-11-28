{ stdenv, fetchzip, autoPatchelfHook, libtiff, lib }: stdenv.mkDerivation rec {
  pname = "codelldb";
  version = "v1.11.8";
  # https://github.com/vadimcn/codelldb

  src = fetchzip {
    url = "https://github.com/vadimcn/codelldb/releases/download/${version}/codelldb-linux-x64.vsix";
    extension = "zip";
    stripRoot = false;
    sha256 = "sha256-ZERLjK5yMcZmctoqx+a1uJz14zElFLKOutDb6zfLzh0=";
  };

  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook ];
  buildInputs = [
    stdenv.cc.cc.lib
    libtiff
  ];

  installPhase = ''
    mkdir -p $out/
    cp -r ./* $out/
  '';

  meta = {
    description = "A debugger for VS Code";
    homepage = "https://github.com/vadimcn/codelldb";
    license = lib.licenses.mit;
    platforms = lib.platforms.linux;
  };
}
