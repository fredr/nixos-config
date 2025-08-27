{ pkgs }:
{
  mirror = pkgs.callPackage ./mirror { };
  stringer = pkgs.callPackage ./stringer { };
  goimports = pkgs.callPackage ./goimports { };
  cargotom = pkgs.callPackage ./cargotom { };
  protobuf-language-server = pkgs.callPackage ./protobuf-language-server { };
}
