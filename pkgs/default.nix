{ pkgs }:
{
  mirror = pkgs.callPackage ./mirror { };
  stringer = pkgs.callPackage ./stringer { };
  cargotom = pkgs.callPackage ./cargotom { };
  protobuf-language-server = pkgs.callPackage ./protobuf-language-server { };
}
