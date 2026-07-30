{
  rustPlatform,
  fetchFromGitHub,
  pkg-config,
  openssl,
}:
# https://github.com/frederik-uni/cargotom

rustPlatform.buildRustPackage rec {
  pname = "cargotom";
  version = "2.3.9";

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ openssl ];

  src = fetchFromGitHub {
    owner = "frederik-uni";
    repo = pname;
    rev = version;
    hash = "sha256-5zE3rpHa2JQBrfLTcuuDBBpTQDoaK74L7TSZZAOwh/8=";
  };

  cargoHash = "sha256-BQJhTq2N8VSv4n/gPo3x8FJQElqw1yrkwuOXxdXTdSo=";

  # A dependency builds an unused html2md cdylib that gets installed into
  # $out/lib. It links against Rust's dynamic std, so its RPATH points into
  # rustc and drags the whole 987MiB compiler into the runtime closure.
  # bin/cargotom references neither the library nor rustc.
  postInstall = ''
    rm -rf "$out/lib"
  '';

  meta = {
    description = "Cargo.toml LSP";
    homepage = "https://github.com/frederik-uni/cargotom";
    license = "";
    maintainers = [ ];
  };
}
