{ rustPlatform, fetchFromGitHub, pkg-config, openssl }:
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

  meta = {
    description = "Cargo.toml LSP";
    homepage = "https://github.com/frederik-uni/cargotom";
    license = "";
    maintainers = [ ];
  };
}
