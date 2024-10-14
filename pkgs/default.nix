{ pkgs }:
{
  mirror = pkgs.callPackage ./mirror { };
  stringer = pkgs.callPackage ./stringer { };
}
