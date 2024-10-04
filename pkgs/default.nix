{ pkgs }:
{
  encore = pkgs.callPackage ./encore { };
  mirror = pkgs.callPackage ./mirror { };
  stringer = pkgs.callPackage ./stringer { };
}
