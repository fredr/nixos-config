{ rustPlatform, fetchFromGitHub }:
# https://github.com/zed-industries/delve-shim-dap

rustPlatform.buildRustPackage rec {
  pname = "delve-shim-dap";
  version = "v0.0.3";

  nativeBuildInputs = [ ];
  buildInputs = [ ];

  src = fetchFromGitHub {
    owner = "zed-industries";
    repo = pname;
    rev = version;
    hash = "sha256-fF19lGZtuT0OMXQfENMgJBlCJ3aD8Z/0Z1wKj/B3xNM=";
  };

  cargoHash = "sha256-UnMqsFicA/6QodKJRi0OiK8JHTytgKgOf3ay6+rirQ8=";

  meta = {
    description = "Delve adapter for Zed";
    homepage = "https://github.com/zed-industries/delve-shim-dap";
    license = "";
    maintainers = [ ];
  };
}
