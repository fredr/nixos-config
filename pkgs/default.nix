{ pkgs }:
{
  mirror = pkgs.callPackage ./mirror { };
  stringer = pkgs.callPackage ./stringer { };
  cargotom = pkgs.callPackage ./cargotom { };
}
