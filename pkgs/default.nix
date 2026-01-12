{ pkgs }:
{
  mirror = pkgs.callPackage ./mirror { };
  stringer = pkgs.callPackage ./stringer { };
  goimports = pkgs.callPackage ./goimports { };
  cargotom = pkgs.callPackage ./cargotom { };
  protobuf-language-server = pkgs.callPackage ./protobuf-language-server { };
  delve-shim-dap = pkgs.callPackage ./delve-shim-dap { };
  codelldb = pkgs.callPackage ./codelldb { };

  # Encore-specific tool versions
  protoc-encore = pkgs.callPackage ./protoc-encore { };
  sqlc-encore = pkgs.callPackage ./sqlc-encore { };
  protoc-gen-go-encore = pkgs.callPackage ./protoc-gen-go-encore { };
  protoc-gen-go-grpc-encore = pkgs.callPackage ./protoc-gen-go-grpc-encore { };
}
